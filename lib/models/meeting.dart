/// 회의 데이터 모델
class Meeting {
  final String id;
  final String title;
  final DateTime dateTime;
  final int duration;
  final String transcript;
  final String minutes;
  final String audioPath;
  final String? instructions;
  final DateTime createdAt;
  final String? notionPageId;
  final bool notionSaved;

  Meeting({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.duration,
    required this.transcript,
    required this.minutes,
    required this.audioPath,
    this.instructions,
    required this.createdAt,
    this.notionPageId,
    this.notionSaved = false,
  });

  Meeting copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    int? duration,
    String? transcript,
    String? minutes,
    String? audioPath,
    String? instructions,
    DateTime? createdAt,
    String? notionPageId,
    bool? notionSaved,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      transcript: transcript ?? this.transcript,
      minutes: minutes ?? this.minutes,
      audioPath: audioPath ?? this.audioPath,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
      notionPageId: notionPageId ?? this.notionPageId,
      notionSaved: notionSaved ?? this.notionSaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'duration': duration,
        'transcript': transcript,
        'minutes': minutes,
        'audioPath': audioPath,
        'instructions': instructions,
        'createdAt': createdAt.toIso8601String(),
        'notionPageId': notionPageId,
        'notionSaved': notionSaved,
      };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        id: json['id'] as String,
        title: json['title'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        duration: json['duration'] as int,
        transcript: json['transcript'] as String,
        minutes: json['minutes'] as String,
        audioPath: json['audioPath'] as String? ?? '',
        instructions: json['instructions'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        notionPageId: json['notionPageId'] as String?,
        notionSaved: json['notionSaved'] as bool? ?? false,
      );
}

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
