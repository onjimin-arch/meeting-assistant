import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/meeting.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/minutes_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'services/platform_stt_service.dart';
import 'services/gemma_inference_service.dart';
import 'services/notion_sync_service.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MeetingAssistantApp(),
    ),
  );
}

class MeetingAssistantApp extends StatelessWidget {
  const MeetingAssistantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF212121),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final PlatformSttService _sttService;
  late final GemmaInferenceService _gemmaInference;

  DateTime? _recordingStartedAt;

  @override
  void initState() {
    super.initState();
    _sttService = PlatformSttService();
    _gemmaInference = GemmaInferenceService();
  }

  Future<void> _startRecording() async {
    // LLM 모델 준비 확인 — 없으면 다운로드 다이얼로그
    final llm = ref.read(llmStateProvider);
    if (llm.status != LlmReadiness.ready) {
      final shouldDownload = await _showModelDownloadDialog();
      if (!shouldDownload) return;
      // 다운로드 시작 (백그라운드에서 진행, UI는 progress dialog)
      await _showDownloadProgressDialog();
      // 다운로드 후 ready가 아니면 중단
      if (ref.read(llmStateProvider).status != LlmReadiness.ready) return;
    }

    try {
      _recordingStartedAt = DateTime.now();
      await _sttService.startListening(localeId: 'ko_KR');
      ref.read(recordingStateProvider.notifier).state = RecordingState.recording;
    } catch (e) {
      debugPrint('STT 시작 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('녹음을 시작할 수 없습니다: $e')),
        );
      }
    }
  }

  Future<bool> _showModelDownloadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2f2f2f),
        title: const Text(
          '회의록 AI 모델 다운로드',
          style: TextStyle(color: Color(0xFFececec)),
        ),
        content: const Text(
          '회의록을 자동 생성하려면 AI 모델(약 530MB)을 한 번만 다운로드해야 합니다.\n\n'
          'Wi-Fi 연결을 권장합니다. 다운로드 후엔 인터넷 없이도 동작합니다.',
          style: TextStyle(color: Color(0xFFececec), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '다운로드',
              style: TextStyle(
                  color: Color(0xFF10a37f), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showDownloadProgressDialog() async {
    // 다운로드 시작
    ref.read(llmStateProvider.notifier).downloadAndLoad();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(llmStateProvider);
          // ready/error가 되면 자동으로 닫음
          if (state.status == LlmReadiness.ready ||
              state.status == LlmReadiness.error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            });
          }
          return AlertDialog(
            backgroundColor: const Color(0xFF2f2f2f),
            title: Text(
              state.status == LlmReadiness.loading
                  ? '모델 로딩 중...'
                  : '모델 다운로드 중',
              style: const TextStyle(color: Color(0xFFececec)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: state.status == LlmReadiness.loading
                      ? null
                      : state.downloadProgress,
                  backgroundColor: const Color(0xFF1a1a1a),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10a37f)),
                ),
                const SizedBox(height: 12),
                Text(
                  state.status == LlmReadiness.loading
                      ? '다운로드 완료. 모델을 메모리에 적재 중입니다.'
                      : '${(state.downloadProgress * 100).toStringAsFixed(1)}%  '
                          '(${_fmtMB(state.downloadedBytes)} / ${_fmtMB(state.totalBytes)})',
                  style: const TextStyle(
                      color: Color(0xFF8e8ea0), fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 다운로드 결과에 따라 사용자에게 알림
    final finalState = ref.read(llmStateProvider);
    if (finalState.status == LlmReadiness.error && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모델 준비 실패: ${finalState.errorMessage ?? "알 수 없는 오류"}'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  String _fmtMB(int bytes) =>
      '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';

  Future<void> _stopRecordingAndProcess() async {
    try {
      // 녹음 중단 → 플랫폼 STT가 누적한 텍스트 회수
      final transcript = await _sttService.stopListening();
      final duration =
          DateTime.now().difference(_recordingStartedAt ?? DateTime.now());

      // 처리 화면 진입
      ref.read(recordingStateProvider.notifier).state = RecordingState.processing;
      final settings = ref.read(appSettingsProvider);

      // Step 1: STT는 녹음 중 실시간으로 완료됨 → 바로 표시만
      ref.read(processingStepProvider.notifier).state = 0;
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: 회의록 생성 (실패해도 스크립트는 저장하기 위해 try-catch 분리)
      ref.read(processingStepProvider.notifier).state = 1;
      String title = '제목 없음';
      String minutes = '';
      bool minutesSuccess = false;

      try {
        final minutesResult = await _gemmaInference.generateMinutes(
          transcript: transcript,
          instructions: settings.minutesInstructions,
        );
        title = minutesResult['title']!;
        minutes = minutesResult['minutes']!;
        minutesSuccess = true;
      } catch (e) {
        debugPrint('회의록 생성 실: $e');
        // 생성 실패 시에도 스크립트는 저장되도록 폴백 데이터 사용
        title = '회의록 (생성 실패)';
        minutes = '회의록 생성에 실패했습니다.\n\n원본 스크립트:\n$transcript';
      }

      // Step 3 (선): Notion 저장
      String? notionPageId;
      bool notionSaved = false;
      if (settings.autoSaveToNotion && minutesSuccess) {
        ref.read(processingStepProvider.notifier).state = 2;
        final notionService = NotionSyncService(
          apiToken: settings.notionToken,
          pageUrl: settings.notionPageUrl,
        );
        try {
          notionPageId = await notionService.saveMinutesToNotion(
            title: title,
            minutes: minutes,
          );
          notionSaved = true;
        } catch (e) {
          debugPrint('Notion 저장 실패: $e');
        }
      }

      // 회의 데이터 생성 및 저장
      final meeting = Meeting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        dateTime: DateTime.now(),
        duration: duration.inSeconds,
        transcript: transcript,
        minutes: minutes,
        audioPath: '', // 플랫폼 STT 사용 시 오디오 파일 미저장 (재생 기능은 후속 단계)
        instructions: settings.minutesInstructions,
        createdAt: DateTime.now(),
        notionPageId: notionPageId,
        notionSaved: notionSaved,
      );

      // 로컬 저장 (Notion 성공/실패와 무관하게 항상 저장됨)
      await ref.read(meetingsProvider.notifier).add(meeting);

      // 상태 업데이트
      ref.read(currentMeetingProvider.notifier).state = meeting;
      ref.read(recordingStateProvider.notifier).state = RecordingState.completed;

      // 1.2초 후 회의록 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        ref.read(recordingStateProvider.notifier).state = RecordingState.idle;
      }
    } catch (e) {
      debugPrint('처리 중 에러: $e');
      ref.read(recordingStateProvider.notifier).state = RecordingState.error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 중 오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingStateProvider);
    final currentMeeting = ref.watch(currentMeetingProvider);
    final processingStep = ref.watch(processingStepProvider);
    final settings = ref.watch(appSettingsProvider);

    // 화면 라우팅
    if (recordingState == RecordingState.recording) {
      return RecordingScreen(onStop: () => _stopRecordingAndProcess());
    } else if (recordingState == RecordingState.processing) {
      return ProcessingScreen(
        step: processingStep,
        autoSave: settings.autoSaveToNotion,
      );
    } else if (recordingState == RecordingState.completed &&
        currentMeeting != null) {
      return MinutesScreen(
        meeting: currentMeeting,
        onBack: () {
          ref.read(recordingStateProvider.notifier).state = RecordingState.idle;
          ref.read(currentMeetingProvider.notifier).state = null;
        },
        onChat: () {
          ref.read(recordingStateProvider.notifier).state = RecordingState.idle;
          _showChatScreen(context, currentMeeting);
        },
        autoSave: settings.autoSaveToNotion,
      );
    }

    // 기본: 홈 화면 (시스템 뒤로가기로 앱 종료되지 않도록 차단)
    return PopScope(
      canPop: false,
      child: HomeScreen(
        onStartRecording: () => _startRecording(),
        onSelectMeeting: (meeting) {
          ref.read(currentMeetingProvider.notifier).state = meeting;
          ref.read(recordingStateProvider.notifier).state =
              RecordingState.completed;
        },
        onSettings: () => _showSettingsScreen(context),
      ),
    );
  }

  void _showChatScreen(BuildContext context, Meeting meeting) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          meeting: meeting,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showSettingsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
