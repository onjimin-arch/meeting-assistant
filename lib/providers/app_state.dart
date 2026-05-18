import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
import '../services/app_settings_service.dart';
import '../services/gemma_inference_service.dart';
import '../services/meeting_repository.dart';
import '../utils/model_downloader.dart';

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

/// LLM 모델 준비 상태
enum LlmReadiness {
  unknown,       // 아직 체크 안 함
  needsDownload, // 캐시 없음 → 다운로드 필요
  downloading,   // 다운로드 진행 중
  loading,       // 다운로드 완료, InferenceModel 로딩 중
  ready,         // 사용 가능
  error,         // 에러 발생
}

class LlmState {
  final LlmReadiness status;
  final double downloadProgress; // 0.0 ~ 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  const LlmState({
    this.status = LlmReadiness.unknown,
    this.downloadProgress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  LlmState copyWith({
    LlmReadiness? status,
    double? downloadProgress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) =>
      LlmState(
        status: status ?? this.status,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        errorMessage: errorMessage,
      );
}

final llmStateProvider =
    StateNotifierProvider<LlmStateNotifier, LlmState>((ref) => LlmStateNotifier());

class LlmStateNotifier extends StateNotifier<LlmState> {
  final _downloader = ModelDownloader();
  final _gemma = GemmaInferenceService();

  LlmStateNotifier() : super(const LlmState()) {
    _initialCheck();
  }

  Future<void> _initialCheck() async {
    final cached = await _downloader.cachedPath(ModelDownloader.defaultModel);
    if (cached == null) {
      state = state.copyWith(status: LlmReadiness.needsDownload);
    } else {
      // 캐시는 있으니 로딩만
      await loadModelFromCache();
    }
  }

  /// 모델 다운로드 (사용자 동의 후 호출)
  Future<void> downloadAndLoad() async {
    state = state.copyWith(
      status: LlmReadiness.downloading,
      downloadProgress: 0,
    );
    try {
      final file = await _downloader.download(
        ModelDownloader.defaultModel,
        onProgress: (p) {
          state = state.copyWith(
            status: LlmReadiness.downloading,
            downloadProgress: p.percent,
            downloadedBytes: p.receivedBytes,
            totalBytes: p.totalBytes,
          );
        },
      );
      state = state.copyWith(status: LlmReadiness.loading);
      await _gemma.ensureReady(file.path);
      state = state.copyWith(status: LlmReadiness.ready);
    } catch (e) {
      state = state.copyWith(
        status: LlmReadiness.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 캐시된 모델 로드
  Future<void> loadModelFromCache() async {
    final cached = await _downloader.cachedPath(ModelDownloader.defaultModel);
    if (cached == null) {
      state = state.copyWith(status: LlmReadiness.needsDownload);
      return;
    }
    state = state.copyWith(status: LlmReadiness.loading);
    try {
      await _gemma.ensureReady(cached);
      state = state.copyWith(status: LlmReadiness.ready);
    } catch (e) {
      state = state.copyWith(
        status: LlmReadiness.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteModel() async {
    await _downloader.deleteCache(ModelDownloader.defaultModel);
    state = const LlmState(status: LlmReadiness.needsDownload);
  }
}

/// 저장된 회의 목록 프로바이더 (로컬 영속화)
final meetingsProvider =
    StateNotifierProvider<MeetingsNotifier, List<Meeting>>(
  (ref) => MeetingsNotifier(),
);

class MeetingsNotifier extends StateNotifier<List<Meeting>> {
  final _repo = MeetingRepository();

  MeetingsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadAll();
  }

  Future<void> add(Meeting meeting) async {
    final updated = await _repo.append(meeting);
    state = updated;
  }

  Future<void> remove(String id) async {
    final updated = await _repo.remove(id);
    state = updated;
  }

  Future<void> updateOne(Meeting meeting) async {
    final updated = await _repo.update(meeting);
    state = updated;
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
