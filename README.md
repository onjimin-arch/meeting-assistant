# Meeting Assistant - Flutter 모바일 앱

온디바이스 AI 기반 회의 자동 기록 & Notion 저장 모바일 앱

## 🎯 프로젝트 목표

- **음성 녹음**: 실시간 마이크 녹음
- **AI 변환**: Whisper Tiny로 음성 → 텍스트 변환
- **회의록 생성**: Gemma 4 2B로 구조화된 회의록 자동 생성
- **Notion 연동**: 생성된 회의록을 Notion 페이지에 저장
- **추가 작업**: 채팅 기반으로 액션아이템 추출, 영문 요약 등 요청

## 📱 주요 기능

| 기능 | 설명 |
|------|------|
| **새 회의 녹음** | 마이크 버튼으로 회의 녹음 시작/종료 |
| **원본 스크립트** | Whisper가 변환한 텍스트 (화자 구분 없음) |
| **회의록 생성** | Gemma가 사용자 지침에 따라 구조화된 마크다운 생성 |
| **Notion 저장** | 수동 또는 자동 (설정에서 토글 가능) |
| **추가 작업 채팅** | 액션아이템 추출, 영문 요약, 임원 보고용 재작성 등 |
| **설정 관리** | Notion API 토큰, 저장 페이지, 자동 저장 옵션 |

## 🛠️ 기술 스택

```
├─ Frontend
│  └─ Flutter (Dart)
│     ├─ Riverpod (상태 관리)
│     ├─ flutter_sound (오디오 녹음)
│     └─ drift (SQLite ORM)
│
├─ AI/ML
│  ├─ Whisper Tiny (~39MB)
│  │  └─ whisper_flutter_new 패키지
│  │
│  └─ Gemma 4 2B (~1.5GB)
│     └─ MediaPipe LLM Inference API
│
└─ Backend/Integration
   ├─ Notion REST API v1 (마크다운 → 블록 변환)
   ├─ SharedPreferences (설정 영속화)
   └─ Local SQLite (회의 데이터 저장)
```

## 📋 설치 및 실행

### 1. 프로젝트 설정

```bash
# 저장소 클론
git clone <repo-url>
cd meeting-assistant

# 의존성 설치
flutter pub get

# 코드 생성 (drift, json_serializable)
flutter pub run build_runner build
```

### 2. 안드로이드 빌드

```bash
# APK 빌드 (디버그)
flutter build apk --debug

# APK 빌드 (릴리스)
flutter build apk --release
```

### 3. iOS 빌드

```bash
# iOS 앱 빌드 (디버그)
flutter build ios --debug

# iOS 앱 빌드 (릴리스)
flutter build ios --release
```

### 4. 실행

```bash
# 에뮬레이터/디바이스에서 실행
flutter run

# 디버그 모드
flutter run -v
```

## ⚙️ 설정

### Notion 연동

1. **Notion Integration 생성**
   - https://www.notion.so/my-integrations
   - "새 통합" 클릭 → 이름 설정 → 생성

2. **API 토큰 복사**
   - Integration 페이지에서 "Internal Integration Token" 복사

3. **저장 페이지 URL 복사**
   - Notion에서 저장할 페이지 → URL 복사

4. **앱 설정 화면에서 입력**
   - Settings 화면 → API 토큰 + 페이지 URL 입력
   - "회의록 완성 시 자동 저장" 토글 (선택)
   - "저장" 버튼 클릭

## 🎨 UI 화면

### 1. Home Screen
- 최근 회의 목록
- "새 회의 녹음" 버튼
- 설정 접근

### 2. Recording Screen
- 실시간 웨이브폼 애니메이션
- 녹음 타이머 (MM:SS)
- 종료 버튼 (빨간 원형)

### 3. Processing Screen
- 단계별 진행 표시
  - Step 1: 음성 인식 중 (Whisper)
  - Step 2: 회의록 생성 중 (Gemma)
  - Step 3: Notion에 저장 중 (조건부)

### 4. Minutes Screen
- 원본 스크립트 (토글식 표시)
- 회의록 본문 (마크다운)
- "추가 작업 요청" 버튼

### 5. Chat Screen
- 빠른 옵션: 액션아이템 추출, 영문 요약, 임원 보고용
- 자유 입력 메시지 필드
- 실시간 채팅 UI

### 6. Settings Screen
- Notion API 토큰 입력
- 저장 페이지 URL 입력
- 자동 저장 토글
- 회의록 작성 지침 입력
- 모델 정보 표시

## 📊 워크플로우

### 메인 플로우: 녹음 → 회의록

```
홈 화면
  ↓
[새 회의 녹음] 버튼 클릭
  ↓
녹음 화면 진입 (타이머 시작, 웨이브폼 표시)
  ↓
[종료 버튼] 클릭 → audioPath 저장
  ↓
처리 화면 (Step 1: STT)
  ↓
Whisper → transcript (원본 스크립트)
  ↓
처리 화면 (Step 2: Gemma)
  ↓
Gemma → {title, minutes} (회의록 생성)
  ↓
[자동 저장 ON?]
  ├─ YES → 처리 화면 (Step 3: Notion)
  │  ↓
  │  Notion API → notionPageId 저장
  │
  └─ NO → 즉시 회의록 화면으로
  ↓
회의록 화면 표시
  ↓
[추가 작업 요청] 또는 [홈으로]
```

### 추가 작업 플로우: 채팅

```
회의록 화면 → [추가 작업 요청] 클릭
  ↓
채팅 화면 진입
  ↓
[빠른 옵션 선택] 또는 [자유 입력]
  ↓
Gemma.processQuery(query, transcript, minutes)
  ↓
LLM 응답
  ↓
채팅 메시지 추가
```

## 🔍 파일 구조

```
meeting-assistant/
├── CLAUDE.md                       # 오케스트레이터 지침
├── pubspec.yaml                    # 의존성
├── README.md                       # 이 파일
│
├── lib/
│   ├── main.dart                   # 앱 진입점 & 네비게이션
│   ├── models/
│   │   └── meeting.dart            # Meeting, AppSettings, ChatMessage, RecordingState
│   ├── services/
│   │   ├── audio_recorder_service.dart
│   │   ├── whisper_stt_service.dart
│   │   ├── gemma_inference_service.dart
│   │   ├── notion_sync_service.dart
│   │   └── app_settings_service.dart
│   ├── providers/
│   │   └── app_state.dart          # Riverpod 프로바이더
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── recording_screen.dart
│   │   ├── processing_screen.dart
│   │   ├── minutes_screen.dart
│   │   ├── chat_screen.dart
│   │   └── settings_screen.dart
│   └── utils/
│       ├── model_downloader.dart
│       └── notion_block_converter.dart
│
├── .claude/
│   ├── agents/
│   │   ├── ai-pipeline.md          # Whisper + Gemma 통합
│   │   └── notion-integration.md   # Notion API 클라이언트
│   └── skills/
│       ├── audio-recorder/
│       ├── whisper-stt/
│       ├── gemma-inference/
│       └── notion-sync/
│
├── assets/
│   └── models/                     # 모델 저장 (런타임)
│
└── docs/
    ├── API.md                      # Notion API 참고
    ├── MODELS.md                   # 모델 스펙
    └── ARCHITECTURE.md             # 아키텍처 설명
```

## 📌 상태 관리 (Riverpod)

### 주요 Providers

```dart
// 앱 설정
appSettingsProvider
  ├─ notionToken: String?
  ├─ notionPageUrl: String?
  ├─ autoSaveToNotion: bool
  └─ minutesInstructions: String?

// 녹음 상태
recordingStateProvider: RecordingState
  ├─ idle
  ├─ recording
  ├─ processing
  ├─ completed
  └─ error

// 현재 회의
currentMeetingProvider: Meeting?

// 처리 진행도
processingStepProvider: int (0-3)

// 채팅 메시지
chatMessagesProvider: List<ChatMessage>
```

## 🧪 테스트

```bash
# 단위 테스트 실행
flutter test

# 통합 테스트
flutter test integration_test/

# 특정 테스트 파일
flutter test test/services/audio_recorder_service_test.dart
```

## 🚀 배포

### Android (APK)

```bash
# 릴리스 빌드
flutter build apk --release

# 출력: build/app/outputs/flutter-app.apk
```

### iOS (IPA)

```bash
# 릴리스 빌드
flutter build ios --release

# Xcode로 아카이브 및 배포
```

## 📝 라이선스

MIT License

## 👨‍💻 개발자 정보

- **프로젝트**: Meeting Assistant
- **버전**: 1.0.0
- **플랫폼**: Flutter (Android + iOS)
- **마지막 업데이트**: 2026년 5월 13일

## 📞 지원

문제가 발생하면:
1. 로그 확인 (`flutter logs`)
2. 캐시 삭제 (`flutter clean`)
3. 의존성 재설치 (`flutter pub get`)
4. 빌드 재실행 (`flutter pub run build_runner build`)

---

**상태**: 🟢 UI 화면 구현 완료 → 🟡 AI 파이프라인 네이티브 통합 진행 중
