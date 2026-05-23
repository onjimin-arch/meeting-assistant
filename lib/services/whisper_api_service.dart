import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WhisperApiService {
  static const String _endpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  static Future<String> transcribe({
    required String audioPath,
    required String apiKey,
    String language = 'ko',
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception('오디오 파일이 없습니다: $audioPath');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = language
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath));

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 5),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.body.trim();
    }

    String errorMsg = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body);
      errorMsg = json['error']?['message'] ?? errorMsg;
    } catch (_) {}
    throw Exception('Whisper API 오류: $errorMsg');
  }
}
