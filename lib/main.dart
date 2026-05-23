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
import 'services/audio_recorder_service.dart';
import 'services/whisper_stt_service.dart';

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
  late final AudioRecorderService _audioRecorderService;
  late final WhisperSttService _whisperService;
  late final GemmaInferenceService _gemmaInference;

  DateTime? _recordingStartedAt;

  @override
  void initState() {
    super.initState();
    _sttService = PlatformSttService();
    _audioRecorderService = AudioRecorderService();
    _whisperService = WhisperSttService();
    _gemmaInference = GemmaInferenceService();
    _sttService.onError = (msg, permanent) {
      if (!mounted) return;
      final label = _sttErrorLabel(msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('음성 인식 오류: $label'),
          duration: const Duration(seconds: 5),
        ),
      );
    };
  }

  @override
  void dispose() {
    _audioRecorderService.close();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final settings = ref.read(appSettingsProvider);
    final sttMode = settings.sttMode;

    // LLM 모델 준비 확인 (파일 기반 모드일 때만 필요)
    if (sttMode == SttMode.fileBased) {
      final llm = ref.read(llmStateProvider);

      if (llm.status == LlmReadiness.needsDownload) {
        final shouldDownload = await _showModelDownloadDialog();
        if (!shouldDownload) return;
        await _showDownloadProgressDialog();
        if (ref.read(llmStateProvider).status != LlmReadiness.ready) return;
      } else if (llm.status == LlmReadiness.loading) {
        await _showLoadingProgressDialog();
        if (ref.read(llmStateProvider).status != LlmReadiness.ready) return;
      } else if (llm.status == LlmReadiness.error) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2f2f2f),
            title: const Text('모델 로드 실패', style: TextStyle(color: Color(0xFFececec))),
            content: Text(
              '모델 준비 중 오류가 발생했습니다.\n${llm.errorMessage ?? ""}\n\n다시 시도하시겠습니까?',
              style: const TextStyle(color: Color(0xFFececec)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('재시도')),
            ],
          ),
        );
        if (shouldRetry == true) {
          await _showDownloadProgressDialog();
          if (ref.read(llmStateProvider).status != LlmReadiness.ready) return;
        } else {
          return;
        }
      }
    }

    try {
      _recordingStartedAt = DateTime.now();

      if (sttMode == SttMode.realTime) {
        // 기존: 플랫폼 내장 STT
        await _sttService.startListening(localeId: 'ko_KR');
      } else {
        // 추가: 오디오 레코더 (AAC 저장)
        await _audioRecorderService.startRecording();
      }

      ref.read(recordingStateProvider.notifier).state = RecordingState.recording;
    } catch (e) {
      debugPrint('녹음 시작 실패: $e');
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
          '회의록을 자동 생성하려면 AI 모델 (약 530MB) 을 한 번만 다운로드해야 합니다.\n\n'
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
    ref.read(llmStateProvider.notifier).downloadAndLoad();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(llmStateProvider);
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
                    : '${(state.downloadProgress * 100).toStringAsFixed(1)}% '
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

  /// 모델 로딩 중 대기 다이얼로그 (캐시된 모델 로드 시)
  Future<void> _showLoadingProgressDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(llmStateProvider);
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
            title: const Text('모델 로딩 중...', style: TextStyle(color: Color(0xFFececec))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF10a37f)),
                const SizedBox(height: 12),
                const Text(
                  '캐시된 모델을 메모리에 적재 중입니다.\n잠시만 기다려 주세요.',
                  style: TextStyle(color: Color(0xFF8e8ea0), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

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

  String _sttErrorLabel(String errorMsg) {
    switch (errorMsg) {
      case 'error_audio': return '마이크 접근 실패 (설정 > 앱 > 마이크 권한 확인)';
      case 'error_permission': return '마이크 권한이 거부되었습니다';
      case 'error_recognizer_busy': return '음성 인식기가 사용 중입니다. 잠시 후 다시 시도하세요';
      case 'error_server': return '음성 인식 서버 오류 (인터넷 연결 확인)';
      case 'error_network': return '네트워크 오류 (인터넷 연결 확인)';
      case 'error_insufficient_permissions': return '마이크 권한이 없습니다';
      default: return errorMsg;
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    final settings = ref.read(appSettingsProvider);
    final sttMode = settings.sttMode;

    String transcript;
    int durationSeconds;

    if (sttMode == SttMode.realTime) {
      // 기존: 플랫폼 STT
      transcript = await _sttService.stopListening();
      durationSeconds = DateTime.now().difference(_recordingStartedAt ?? DateTime.now()).inSeconds;
    } else {
      // 추가: 오디오 저장 → Whisper 로컬 변환
      final audioPath = await _audioRecorderService.stopRecording();
      durationSeconds = DateTime.now().difference(_recordingStartedAt ?? DateTime.now()).inSeconds;
      
      try {
        transcript = await _whisperService.transcribe(audioPath!);
      } catch (e) {
        debugPrint('Whisper 변환 실패: $e');
        transcript = '(변환 실패: ${e.toString()})';
      }
    }

    await _processTranscript(transcript, durationSeconds);
  }

  Future<void> _processTranscript(String transcript, int durationSeconds) async {
    try {
      ref.read(recordingStateProvider.notifier).state = RecordingState.processing;
      final settings = ref.read(appSettingsProvider);

      ref.read(processingStepProvider.notifier).state = 0;
      await Future.delayed(const Duration(milliseconds: 300));

      ref.read(processingStepProvider.notifier).state = 1;
      String title = '제목 없음';
      String minutes = '';
      bool minutesSuccess = false;
      String? gemmaError;

      try {
        final minutesResult = await _gemmaInference.generateMinutes(
          transcript: transcript,
          instructions: settings.minutesInstructions,
        );
        title = minutesResult['title']!;
        minutes = minutesResult['minutes']!;
        minutesSuccess = true;
      } catch (e) {
        debugPrint('회의록 생성 실패: $e');
        gemmaError = e.toString();
        title = '회의록 (생성 실패)';
        minutes = '회의록 생성에 실패했습니다.\n\n원본 스크립트:\n$transcript';
      }

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
            dateTime: DateTime.now(),
          );
          notionSaved = true;
        } catch (e) {
          debugPrint('Notion 저장 실패: $e');
        }
      }

      final meeting = Meeting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        dateTime: DateTime.now(),
        duration: durationSeconds,
        transcript: transcript,
        minutes: minutes,
        audioPath: '',
        instructions: settings.minutesInstructions,
        createdAt: DateTime.now(),
        notionPageId: notionPageId,
        notionSaved: notionSaved,
      );

      await ref.read(meetingsProvider.notifier).add(meeting);
      ref.read(currentMeetingProvider.notifier).state = meeting;
      ref.read(recordingStateProvider.notifier).state = RecordingState.completed;

      if (gemmaError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회의록 생성 중 오류가 발생했습니다. 원본 스크립트만 저장되었습니다.\n($gemmaError)'),
            duration: const Duration(seconds: 8),
            backgroundColor: const Color(0xFF8B4513),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('처리 중 에러: $e');
      debugPrint('스택 트레이스: $stackTrace');
      ref.read(recordingStateProvider.notifier).state = RecordingState.error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: '닫기',
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
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
          debugPrint('[NAV] onSelectMeeting: ${meeting.title}');
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
