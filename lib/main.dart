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

      // Step 2: 회의록 생성
      ref.read(processingStepProvider.notifier).state = 1;
      final minutesResult = await _gemmaInference.generateMinutes(
        transcript: transcript,
        instructions: settings.minutesInstructions,
      );

      final title = minutesResult['title']!;
      final minutes = minutesResult['minutes']!;

      // Step 3 (선택): Notion 저장
      String? notionPageId;
      bool notionSaved = false;
      if (settings.autoSaveToNotion) {
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
