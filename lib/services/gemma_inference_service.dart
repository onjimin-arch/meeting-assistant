import 'package:flutter/foundation.dart';

/// Gemma 온디바이스 추론 스텁 — flutter_gemma 의존성 제거로 인해 비활성화.
/// 인터페이스는 유지하여 컴파일 오류 없이 빌드 가능.
class GemmaInferenceService {
  static final GemmaInferenceService _instance =
      GemmaInferenceService._internal();
  factory GemmaInferenceService() => _instance;
  GemmaInferenceService._internal();

  bool get isReady => false;

  Future<void> ensureReady(String modelFilePath) async {
    debugPrint('[Gemma] Gemma is disabled in this build.');
    throw UnsupportedError('Gemma 온디바이스 LLM은 현재 빌드에서 지원되지 않습니다.');
  }

  Future<Map<String, String>> generateMinutes({
    required String transcript,
    String? instructions,
  }) async {
    throw UnsupportedError('Gemma 온디바이스 LLM은 현재 빌드에서 지원되지 않습니다.');
  }

  Future<String> processQuery({
    required String query,
    required String transcript,
    required String minutes,
  }) async {
    throw UnsupportedError('Gemma 온디바이스 LLM은 현재 빌드에서 지원되지 않습니다.');
  }
}
