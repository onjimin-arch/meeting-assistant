/// 채팅 메시지 모델
class ChatMessage {
  /// 역할: 'user' 또는 'assistant'
  final String role;

  /// 메시지 텍스트
  final String text;

  /// 타임스탬프
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

/// 앱 설정 모델
class AppSettings {
  /// Notion API 토큰
  final String? notionToken;

  /// Notion 저장 페이지 URL
  final String? notionPageUrl;

  /// 회의록 완성 시 자동 저장 여부
  final bool autoSaveToNotion;

  /// 회의록 작성 지침
  final String? minutesInstructions;

  /// OpenAI API 키 (Whisper STT + 선택적으로 GPT 회의록 생성)
  final String? openaiApiKey;

  /// 회의록 생성 엔진: true = OpenAI GPT, false = 온디바이스 Gemma
  final bool useCloudLlm;

  AppSettings({
    this.notionToken,
    this.notionPageUrl,
    this.autoSaveToNotion = false,
    this.minutesInstructions,
    this.openaiApiKey,
    this.useCloudLlm = false,
  });

  AppSettings copyWith({
    String? notionToken,
    String? notionPageUrl,
    bool? autoSaveToNotion,
    String? minutesInstructions,
    String? openaiApiKey,
    bool? useCloudLlm,
  }) {
    return AppSettings(
      notionToken: notionToken ?? this.notionToken,
      notionPageUrl: notionPageUrl ?? this.notionPageUrl,
      autoSaveToNotion: autoSaveToNotion ?? this.autoSaveToNotion,
      minutesInstructions: minutesInstructions ?? this.minutesInstructions,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      useCloudLlm: useCloudLlm ?? this.useCloudLlm,
    );
  }
}

/// 녹음 상태 enum
enum RecordingState {
  idle, // 초기 상태
  recording, // 녹음 중
  processing, // 처리 중 (STT, Gemma)
  completed, // 완료
  error, // 에러
}
