import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAiLlmService {
  static const String _endpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  static Future<Map<String, String>> generateMinutes({
    required String transcript,
    required String apiKey,
    String? instructions,
  }) async {
    if (transcript.trim().length < 50) {
      throw ArgumentError(
        '스크립트 내용이 너무 짧아 회의록을 생성할 수 없습니다. (최소 50자)',
      );
    }

    final prompt = _buildPrompt(transcript, instructions);

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0.3,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content =
          json['choices'][0]['message']['content'] as String;
      return _parseResponse(content, transcript);
    }

    String errorMsg = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body);
      errorMsg = json['error']?['message'] ?? errorMsg;
    } catch (_) {}
    throw Exception('OpenAI API 오류: $errorMsg');
  }

  static String _buildPrompt(String transcript, String? instructions) {
    final extra = (instructions == null || instructions.trim().isEmpty)
        ? ''
        : '\n\n[추가 작성 지침]\n$instructions\n';
    return '''다음은 회의를 음성 인식으로 받아쓴 원본 텍스트입니다. 이 내용을 바탕으로 깔끔한 회의록을 작성해 주세요.

[규칙]
- 첫 줄에 회의 제목 1줄만 (예: "TITLE: 2025 Q2 전략 회의")
- 두 번째 줄부터는 마크다운 회의록 본문
- 본문에는 일시(추정), 참석자(언급된 사람), 주요 안건, 결정사항, 다음 액션 아이템(담당자/기한 포함)을 정리
- **절대 환각 금지**: 원본 스크립트에 없는 내용, 사실, 이름, 날짜, 수치를 절대 만들지 말 것.
- 모호한 부분은 "(불명확)"으로 표기하고, 추측하지 말 것.
- 한국어로 작성$extra

[원본 transcript]
$transcript

위 규칙대로 작성:''';
  }

  static Future<String> processQuery({
    required String query,
    required String transcript,
    required String minutes,
    required String apiKey,
  }) async {
    final prompt = '''당신은 회의 보조 AI입니다. 아래 회의 자료를 참고해 사용자의 요청에 답하세요.

[회의 원본 transcript]
$transcript

[정리된 회의록]
$minutes

[사용자 요청]
$query

원본 회의 내용에 없는 사실은 만들지 말고, 회의 자료를 근거로 답변하세요.
한국어로 답변:''';

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0.5,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['choices'][0]['message']['content'] as String).trim();
    }

    String errorMsg = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body);
      errorMsg = json['error']?['message'] ?? errorMsg;
    } catch (_) {}
    throw Exception('OpenAI API 오류: $errorMsg');
  }

  static Map<String, String> _parseResponse(
      String response, String fallback) {
    final lines = response.trim().split('\n');
    String title = '회의록';
    String body = response.trim();

    if (lines.isNotEmpty) {
      final first = lines.first.trim();
      final match =
          RegExp(r'^(?:TITLE|제목)\s*[:：]\s*(.+)$').firstMatch(first);
      if (match != null) {
        title = match.group(1)!.trim();
        body = lines.skip(1).join('\n').trim();
      }
    }

    if (body.isEmpty) {
      body = '회의록 생성에 실패했습니다.\n\n원본 transcript:\n$fallback';
    }

    return {'title': title, 'minutes': body};
  }
}
