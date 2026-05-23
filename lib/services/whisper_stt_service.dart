// Whisper Dart 는 실제 존재하지 않는 패키지입니다.
// 이 파일은 더 이상 사용되지 않습니다.
// 파일 기반 STT 는 추후 구현 예정입니다.

/// 더미 클래스 - 실제 사용 안 함
class WhisperSttService {
  bool get isInitialized => false;
  bool get isDownloading => false;
  double get downloadProgress => 0.0;

  Future<void> initialize() async {
    throw UnsupportedError('WhisperSttService 는 더 이상 지원되지 않습니다.');
  }

  Future<String> transcribe(String audioPath) async {
    throw UnsupportedError('WhisperSttService 는 더 이상 지원되지 않습니다.');
  }

  Future<void> deleteModel() async {
    throw UnsupportedError('WhisperSttService 는 더 이상 지원되지 않습니다.');
  }
}
