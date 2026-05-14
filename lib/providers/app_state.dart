import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
import '../services/app_settings_service.dart';

/// 앱 설정 프로바이더
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final _service = AppSettingsService();

  AppSettingsNotifier() : super(AppSettings()) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _service.loadSettings();
    state = settings;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _service.saveSettings(settings);
    state = settings;
  }

  Future<void> updateNotionSettings({
    required String token,
    required String pageUrl,
  }) async {
    final updated = state.copyWith(
      notionToken: token,
      notionPageUrl: pageUrl,
    );
    await updateSettings(updated);
  }

  Future<void> toggleAutoSave(bool value) async {
    final updated = state.copyWith(autoSaveToNotion: value);
    await updateSettings(updated);
  }

  Future<void> updateMinutesInstructions(String instructions) async {
    final updated = state.copyWith(minutesInstructions: instructions);
    await updateSettings(updated);
  }
}

/// 녹음 상태 프로바이더
final recordingStateProvider = StateProvider<RecordingState>((ref) {
  return RecordingState.idle;
});

/// 현재 회의 프로바이더
final currentMeetingProvider =
    StateProvider<Meeting?>((ref) {
  return null;
});

/// 처리 진행 상태 (0-3)
final processingStepProvider = StateProvider<int>((ref) {
  return 0;
});

/// 채팅 메시지 목록 프로바이더
final chatMessagesProvider =
    StateProvider<List<ChatMessage>>((ref) {
  return [
    ChatMessage(
      role: 'assistant',
      text: '안녕하세요! 이 회의 내용을 기반으로 추가 작업을 요청하거나 궁금한 내용을 질문해 보세요.',
      timestamp: DateTime.now(),
    ),
  ];
});
