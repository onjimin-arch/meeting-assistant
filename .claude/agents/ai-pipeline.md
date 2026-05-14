---
title: AI Pipeline Subagent - Whisper + Gemma 온디바이스 통합
description: whisper_flutter_new + MediaPipe LLM Inference API 네이티브 구현
---

# AI Pipeline 서브에이전트

**목표**: Flutter 앱에서 Whisper Tiny + Gemma 4 2B를 완전한 온디바이스 파이프라인으로 통합

**담당 영역**:
- STT: Whisper Tiny 오디오 → 텍스트 변환
- LLM: Gemma 4 2B 텍스트 처리 (회의록 생성, 채팅)
- 모델 관리: 첫 실행 시 다운로드, 캐싱, 버전 관리

---

## 구현 범위

### 1. WhisperSTTService 실제 구현

**파일**: `lib/services/whisper_stt_service.dart`

```dart
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class WhisperSTTService {
  late Whisper _whisper;
  
  /// 초기화 (첫 실행 시 모델 다운로드)
  Future<void> initialize() async {
    _whisper = Whisper.instance;
    
    // 1. 모델 경로 확인
    final modelDir = await _getModelDirectory();
    final modelPath = '$modelDir/whisper-tiny.bin';
    
    // 2. 모델 없으면 다운로드
    if (!await File(modelPath).exists()) {
      await _downloadModel(modelPath);
    }
    
    // 3. 모델 로드
    await _whisper.loadModel(modelPath: modelPath);
  }
  
  /// 오디오 파일 변환
  Future<String> transcribeAudio(String audioPath) async {
    try {
      final result = await _whisper.transcribe(
        audioPath: audioPath,
        language: 'ko', // 한국어
      );
      return result.result ?? '';
    } catch (e) {
      throw Exception('STT 변환 실패: $e');
    }
  }
  
  /// 모델 디렉토리 획득
  Future<String> _getModelDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }
  
  /// 모델 다운로드 (HuggingFace)
  Future<void> _downloadModel(String targetPath) async {
    const url = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('모델 다운로드 실패: ${response.statusCode}');
    }
    
    await File(targetPath).writeAsBytes(response.bodyBytes);
  }
}
```

### 2. GemmaInferenceService 실제 구현

**파일**: `lib/services/gemma_inference_service.dart`

```dart
import 'package:google_mediapipe/google_mediapipe.dart';

class GemmaInferenceService {
  late LLMInference _llm;
  
  /// 초기화 (모델 다운로드 및 로드)
  Future<void> initialize() async {
    // 1. 모델 경로 확인
    final modelDir = await _getModelDirectory();
    final modelPath = '$modelDir/gemma-2b.task';
    
    // 2. 모델 없으면 다운로드
    if (!await File(modelPath).exists()) {
      await _downloadModel(modelPath);
    }
    
    // 3. LLM Inference 초기화
    _llm = LLMInference.create(modelPath: modelPath);
  }
  
  /// 회의록 생성 (제목 포함)
  Future<Map<String, String>> generateMinutes({
    required String transcript,
    String? instructions,
  }) async {
    final systemPrompt = instructions ?? _defaultInstructions();
    
    const userPrompt = '''다음 회의 스크립트를 기반으로 회의록을 생성하세요.
    
스크립트:
$transcript

JSON 형식으로 다음을 포함하여 응답하세요:
{"title": "회의 제목", "minutes": "## 회의록\\n..."}''';
    
    final response = await _llm.generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.7,
      maxTokens: 2000,
    );
    
    // JSON 파싱
    try {
      final json = jsonDecode(response);
      return {
        'title': json['title'] ?? '회의',
        'minutes': json['minutes'] ?? '',
      };
    } catch (e) {
      // 파싱 실패 시 폴백
      return {
        'title': '${DateFormat('yyMMdd').format(DateTime.now())}_회의',
        'minutes': response,
      };
    }
  }
  
  /// 채팅 쿼리 처리
  Future<String> processQuery({
    required String query,
    required String transcript,
    required String minutes,
  }) async {
    const systemPrompt = '당신은 회의록 분석 전문가입니다.';
    
    final userPrompt = '''회의 내용:
$transcript

회의록:
$minutes

질문: $query

답변:''';
    
    return await _llm.generateResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.5,
      maxTokens: 1000,
    );
  }
  
  /// 기본 시스템 지침
  String _defaultInstructions() => '''
    회의록을 다음 구조로 작성하세요:
    - 일시, 참석자, 목적
    - 주요 안건 (구체적인 결과 포함)
    - 결정 사항
    - 액션아이템 (담당자, 마감일)
    - 다음 회의 일정
    ''';
  
  /// 모델 디렉토리
  Future<String> _getModelDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }
  
  /// Gemma 모델 다운로드 (Google MediaPipe)
  Future<void> _downloadModel(String targetPath) async {
    const url = 'https://ai.google.dev/gemma/download?model=gemma-2b-it';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('모델 다운로드 실패: ${response.statusCode}');
    }
    
    await File(targetPath).writeAsBytes(response.bodyBytes);
  }
}
```

---

## Android 네이티브 설정

### android/build.gradle

```gradle
dependencies {
    // Whisper FFI
    implementation 'com.github.ggerganov:whisper.cpp:android'
    
    // MediaPipe LLM
    implementation 'com.google.mediapipe:mediapipe-genai:0.1.0'
}
```

### android/app/src/main/AndroidManifest.xml

```xml
<manifest>
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  
  <application>
    <!-- MediaPipe GPU 지원 (선택사항) -->
    <meta-data
        android:name="com.google.mediapipe.enableGPU"
        android:value="true" />
  </application>
</manifest>
```

---

## iOS 네이티브 설정

### ios/Podfile

```ruby
target 'Runner' do
  pod 'Whisper', '~> 1.0'
  pod 'MediaPipeGenAI', '~> 0.1'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
```

### ios/Runner/Info.plist

```xml
<dict>
  <key>NSMicrophoneUsageDescription</key>
  <string>회의 녹음을 위해 마이크 접근 권한이 필요합니다</string>
  <key>NSLocalNetworkUsageDescription</key>
  <string>온디바이스 모델 처리 시 필요합니다</string>
</dict>
```

---

## 모델 다운로드 관리 (ModelDownloader)

**파일**: `lib/utils/model_downloader.dart`

```dart
class ModelDownloader {
  static const String _whisperUrl = 
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin';
  static const String _gemmaUrl = 
    'https://ai.google.dev/gemma/download?model=gemma-2b-it';
  
  /// 모든 모델 다운로드 (첫 실행 시)
  static Future<bool> downloadAllModels({
    required Function(String message, double progress) onProgress,
  }) async {
    try {
      await _downloadWhisper(onProgress);
      await _downloadGemma(onProgress);
      return true;
    } catch (e) {
      debugPrint('모델 다운로드 실패: $e');
      return false;
    }
  }
  
  static Future<void> _downloadWhisper(
    Function(String message, double progress) onProgress,
  ) async {
    onProgress('Whisper Tiny 모델 다운로드 중...', 0.0);
    
    final request = http.Request('GET', Uri.parse(_whisperUrl));
    final streamResponse = await request.send();
    
    final contentLength = streamResponse.contentLength;
    int downloaded = 0;
    
    final modelPath = await _getModelPath('whisper-tiny.bin');
    final file = File(modelPath);
    final sink = file.openWrite();
    
    streamResponse.stream.listen((chunk) {
      downloaded += chunk.length;
      final progress = downloaded / contentLength;
      onProgress('Whisper 다운로드: ${(progress * 100).toStringAsFixed(0)}%', progress);
      sink.add(chunk);
    });
    
    await sink.close();
  }
  
  static Future<void> _downloadGemma(
    Function(String message, double progress) onProgress,
  ) async {
    onProgress('Gemma 4 2B 모델 다운로드 중...', 0.0);
    
    // Gemma 다운로드 로직 (유사)
    // ...
  }
  
  static Future<String> _getModelPath(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return '${modelDir.path}/$filename';
  }
}
```

---

## 테스트 케이스

### 1. STT 테스트
```dart
test('Whisper STT 변환 정상 동작', () async {
  final service = WhisperSTTService();
  await service.initialize();
  
  final audioPath = 'assets/test_audio.m4a';
  final transcript = await service.transcribeAudio(audioPath);
  
  expect(transcript.isNotEmpty, true);
  expect(transcript.length, greaterThan(50));
});
```

### 2. LLM 테스트
```dart
test('Gemma 회의록 생성', () async {
  final service = GemmaInferenceService();
  await service.initialize();
  
  const transcript = '이지민: 네, Q2 전략을 얘기해 봅시다.';
  final result = await service.generateMinutes(transcript: transcript);
  
  expect(result.containsKey('title'), true);
  expect(result.containsKey('minutes'), true);
  expect(result['title']!.length, greaterThan(0));
});
```

---

## 성능 고려사항

| 항목 | 예상치 | 최적화 방법 |
|------|--------|----------|
| Whisper Tiny 초기화 | ~2초 | 백그라운드 로딩 |
| STT 변환 (1분 오디오) | ~5초 | GPU 활용 (가능 시) |
| Gemma 추론 (500자) | ~3초 | 토큰 제한 (maxTokens) |
| 메모리 사용 | ~600MB | 모델 오프로딩 |

---

## 완료 체크리스트

- [ ] WhisperSTTService 구현 (ffmpeg, FFI 바인딩 검증)
- [ ] GemmaInferenceService 구현 (MediaPipe API 검증)
- [ ] Android 네이티브 설정
- [ ] iOS 네이티브 설정
- [ ] ModelDownloader 구현
- [ ] 모델 캐싱 및 버전 관리
- [ ] 에러 처리 (네트워크, 메모리 부족)
- [ ] 단위 테스트 작성

**산출물**: WhisperSTTService, GemmaInferenceService, ModelDownloader 실제 구현 완료
