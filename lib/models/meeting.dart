/// 회의 모델
class Meeting {
  /// 고유 ID
  final String id;

  /// 회의 제목
  final String title;

  /// 회의 일시
  final DateTime dateTime;

  /// 녹음 소요 시간 (초)
  final int duration;

  /// 원본 스크립트 (Whisper 변환 텍스트)
  final String transcript;

  /// 회의록 (마크다운)
  final String minutes;

  /// 오디오 파일 경로
  final String audioPath;

  /// 작성 지침 (해당 회의에 적용된)
  final String? instructions;

  /// 생성 타임스탬프
  final DateTime createdAt;

  /// Notion 페이지 ID (저장되었으면 포함)
  final String? notionPageId;

  /// Notion 저장 여부
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

/// STT 모드
enum SttMode {
  realTime, // 기존: 플랫폼 내장 STT (실시간 받아쓰기)
  fileBased, // 추가: 파일 저장 후 Whisper 로컬 변환
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

  /// STT 모드
  final SttMode sttMode;

  AppSettings({
    this.notionToken,
    this.notionPageUrl,
    this.autoSaveToNotion = false,
    this.minutesInstructions,
    this.sttMode = SttMode.realTime,
  });

  AppSettings copyWith({
    String? notionToken,
    String? notionPageUrl,
    bool? autoSaveToNotion,
    String? minutesInstructions,
    SttMode? sttMode,
  }) {
    return AppSettings(
      notionToken: notionToken ?? this.notionToken,
      notionPageUrl: notionPageUrl ?? this.notionPageUrl,
      autoSaveToNotion: autoSaveToNotion ?? this.autoSaveToNotion,
      minutesInstructions: minutesInstructions ?? this.minutesInstructions,
      sttMode: sttMode ?? this.sttMode,
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

/// STT 모드 enum
enum SttMode {
  realTime, // 기존: 플랫폼 내장 STT (실시간 받아쓰기)
  fileBased, // 추가: 파일 저장 후 Whisper 로컬 변환
}
