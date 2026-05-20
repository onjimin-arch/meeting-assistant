import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
// ModelType, PreferredBackend enum은 main entry에서 export되지 않으므로 직접 import.
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

/// 회의록 생성 + 후속 채팅 처리.
///
/// `flutter_gemma`를 통해 MediaPipe LLM Inference를 호출한다.
/// 모델 파일(.task)은 [ModelDownloader]가 미리 다운로드해서 디스크에 두고,
/// 이 서비스가 해당 경로를 setModelPath로 등록한 뒤 추론 모델을 만든다.
///
/// **모델이 준비되지 않은 상태에서 호출하면 명확한 예외를 던진다.**
/// 호출자(앱 셸)는 먼저 [ensureReady]를 호출해 모델 가용성을 확인해야 함.
class GemmaInferenceService {
  static final GemmaInferenceService _instance =
      GemmaInferenceService._internal();
  factory GemmaInferenceService() => _instance;
  GemmaInferenceService._internal();

  InferenceModel? _model;
  String? _loadedModelPath;

  bool get isReady => _model != null;

  /// 모델 파일 경로를 등록하고 InferenceModel을 생성한다.
  /// 이미 같은 경로로 로드되어 있으면 no-op.
  Future<void> ensureReady(String modelFilePath) async {
    if (_model != null && _loadedModelPath == modelFilePath) return;

    debugPrint('[Gemma] 모델 로드 시작: $modelFilePath');
    final plugin = FlutterGemmaPlugin.instance;
    await plugin.modelManager.setModelPath(modelFilePath);

    // CPU 백엔드 사용 (대부분 폰에서 안정적).
    // GPU는 일부 기기에서 OOM/크래시 발생 가능.
    _model = await plugin.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.cpu,
      maxTokens: 2048,
    );
    _loadedModelPath = modelFilePath;
    debugPrint('[Gemma] 모델 로드 완료');
  }

  /// 회의록 생성 — transcript를 받아 {title, minutes} 반환
  Future<Map<String, String>> generateMinutes({
    required String transcript,
    String? instructions,
  }) async {
    if (_model == null) {
      throw StateError(
        '회의록 모델이 아직 준비되지 않았습니다. 설정에서 모델을 먼저 다운로드해 주세요.',
      );
    }

    // 스크립트 글자수 검증 (너무 짧으면 회의록 생성 불가)
    if (transcript.trim().length < 50) {
      throw ArgumentError(
        '스크립트 내용이 너무 짧아 회의록을 생성할 수 없습니다 (최소 50자 필요).',
      );
    }

    final prompt = _buildMinutesPrompt(transcript, instructions);
    debugPrint('[Gemma] 회의록 생성 시작 (prompt ${prompt.length}자)');

    try {
      final session = await _model!.createSession(
        temperature: 0.3,
        randomSeed: 1,
        topK: 40,
      );
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      await session.close();

      debugPrint('[Gemma] 회의록 생성 완료 (${response.length}자)');
      return _parseMinutesResponse(response, transcript);
    } catch (e) {
      debugPrint('[Gemma] 회의록 생성 실패: $e');
      rethrow;
    }
  }

  /// 채팅 — 회의 맥락 기반으로 사용자 질의 응답
  Future<String> processQuery({
    required String query,
    required String transcript,
    required String minutes,
  }) async {
    if (_model == null) {
      throw StateError('회의록 모델이 아직 준비되지 않았습니다.');
    }

    final prompt = _buildChatPrompt(query, transcript, minutes);
    debugPrint('[Gemma] 채팅 응답 생성 시작');

    try {
      final session = await _model!.createSession(
        temperature: 0.5,
        randomSeed: DateTime.now().millisecondsSinceEpoch % 100000,
        topK: 40,
      );
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      await session.close();
      return response.trim();
    } catch (e) {
      debugPrint('[Gemma] 채팅 실패: $e');
      rethrow;
    }
  }

  /// 회의록 작성 프롬프트 구성
  String _buildMinutesPrompt(String transcript, String? instructions) {
    final extra = (instructions == null || instructions.trim().isEmpty)
        ? ''
        : '\n\n[추가 작성 지침]\n$instructions\n';
    return '''다음은 회의를 음성 인식으로 받아쓴 원본 텍스트입니다. 이 내용을 바탕으로 깔끔한 회의록을 작성해 주세요.

[규칙]
- 첫 줄에 회의 제목 1줄만 (예: "TITLE: 2025 Q2 전략 회의")
- 두 번째 줄부터는 마크다운 회의록 본문
- 본문에는 일시(추정), 참석자(언급된 사람), 주요 안건, 결정사항, 다음 액션 아이템(담당자/기한 포함)을 정리
- **절대 환각 금지**: 원본 크립트에 없는 내용, 사실, 이름, 날짜, 수치를 절대 만들지 말 것.
- 모호한 부분은 "(불명확)"으로 표기하고, 추측하지 말 것.
- 한국어로 작성$extra

[원본 transcript]
$transcript

위 규칙대로 작성:''';
  }

  /// 채팅 프롬프트 구성
  String _buildChatPrompt(String query, String transcript, String minutes) {
    return '''당신은 회의 보조 AI입니다. 아래 회의 자료를 참고해 사용자의 요청에 답하세요.

[회의 원본 transcript]
$transcript

[정리된 회의록]
$minutes

[사용자 요청]
$query

원본 회의 내용에 없는 사실은 만들지 말고, 회의 자료를 근거로 답변하세요.
한국어로 답변:''';
  }

  /// 모델 응답에서 TITLE 라인과 본문 분리
  Map<String, String> _parseMinutesResponse(
      String response, String fallbackTranscript) {
    final lines = response.trim().split('\n');
    String title = '회의록';
    String body = response.trim();

    // 첫 줄에 "TITLE:" 패턴이 있으면 추출
    if (lines.isNotEmpty) {
      final first = lines.first.trim();
      final match = RegExp(r'^(?:TITLE|제목)\s*[:：]\s*(.+)$').firstMatch(first);
      if (match != null) {
        title = match.group(1)!.trim();
        body = lines.skip(1).join('\n').trim();
      }
    }

    // 본문이 비어있으면 fallback
    if (body.isEmpty) {
      body = '회의록 생성에 실패했습니다.\n\n원본 transcript:\n$fallbackTranscript';
    }

    return {'title': title, 'minutes': body};
  }
}
