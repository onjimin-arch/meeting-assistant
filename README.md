# Meeting Assistant - Flutter 모바일 앱

AI 기반 회의 자동 기록 & Notion 저장 모바일 앱

## 🎯 프로젝트 목표

- **음성 녹음**: 실시간 마이크 녹음 (AAC-LC, 128kbps, 44.1kHz)
- **AI 변환**: OpenAI Whisper API 로 음성 → 텍스트 변환 (클라우드, 한국어 최적화)
- **회의록 생성**: OpenAI GPT 또는 Gemma 온디바이스 LLM 선택 가능
- **Notion 연동**: 생성된 회의록을 Notion 페이지에 저장
- **추가 작업**: 채팅 기반으로 액션아이템 추출, 영문 요약 등 요청

## 📱 주요 기능

| 기능 | 설명 |
|------|------|
| **새 회의 녹음** | 마이크 버튼으로 회의 녹음 시작/종료 |
| **원본 스크립트** | Whisper 가 변환한 원본 텍스트 |
| **회의록 생성** | OpenAI GPT 또는 Gemma 가 사용자 지침에 따라 구조화된 마크다운 생성 |
| **LLM 엔진 선택** | 설정에서 OpenAI GPT(클라우드) 또는 Gemma(온디바이스) 선택 가능 |
| **Notion 저장** | 수동 또는 자동 (설정에서 토글 가능) |
| **추가 작업 채팅** | 액션아이템 추출, 영문 요약, 임원 보고용 재작성 등 |
| **설정 관리** | OpenAI API 키, Notion 토큰, LLM 엔진 선택, 자동 저장 옵션 |

## 🛠️ 기술 스택

```
├─ Frontend
│  └─ Flutter (Dart)
│     ├─ Riverpod (상태 관리)
│     ├─ record (오디오 녹음)
│     └─ flutter_gemma (Gemma 온디바이스)
│
├─ AI/ML
│  ├─ OpenAI Whisper API (음성 → 텍스트, 클라우드)
│  ├─ OpenAI GPT-4o-mini (회의록 생성, 클라우드)
│  └─ Gemma 3 1B Instruct (회의록 생성, 온디바이스)
│
└─ Backend/Integration
   ├─ Notion REST API v1 (마크다운 → 블록 변환)
   ├─ SharedPreferences (설정 + 회의 목록 JSON)
   └─ HTTP (OpenAI API, Notion API)
```

### 버전 정보

| 항목 | 값 |
|------|-----|
| Flutter | stable |
| Dart | ≥3.0 |
| OpenAI 모델 | `whisper-1`, `gpt-4o-mini` |
| Gemma 모델 | Gemma 3 1B Instruct int4 (~530MB) |
| Android minSdk | 24 (Android 7.0) |
| Android compileSdk | 35 |

## 📋 설치 및 실행

### 1. 선수 조건

1. **OpenAI API 키 발급**
   - https://platform.openai.com/api-keys
   - Whisper STT 및 GPT LLM 에 필요

2. **Notion 연동 설정** (선택)
   - https://www.notion.so/my-integrations
   - Integration 생성 후 토큰 복사

### 2. 프로젝트 설정

```bash
# 저장소 클론
git clone <repo-url>
cd meeting-assistant

# 의존성 설치
flutter pub get

# 코드 생성 (drift, json_serializable 사용 시)
flutter pub run build_runner build
```

### 3. 안드로이드 빌드

```bash
# APK 빌드 (디버그)
flutter build apk --debug

# APK 빌드 (릴리스)
flutter build apk --release
```

### 4. iOS 빌드

```bash
# iOS 앱 빌드 (디버그)
flutter build ios --debug

# iOS 앱 빌드 (릴리스)
flutter build ios --release
```

### 5. 실행

```bash
# 에뮬레이터/디바이스에서 실행
flutter run

# 디버그 모드
flutter run -v
```

## ⚙️ 설정

### 1. OpenAI API 키 설정

1. 앱 실행 후 설정 화면 진입
2. **OpenAI API 키** 입력
3. 저장

### 2. LLM 엔진 선택

1. 설정 화면 → **LLM 엔진 선택**
2. 다음 중 선택:
   - **OpenAI GPT (클라우드)**: 정확한 회의록, API 키 필요
   - **Gemma 온디바이스**: 오프라인 동작, 첫 사용 시 모델 다운로드 (~530MB)
3. 선택 시 즉시 적용

### 3. Notion 연동

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
- 최근 회의 목록 (최신순)
- "새 회의 녹음" 버튼
- 설정 아이콘

### 2. Recording Screen
- 실시간 웨이브폼 애니메이션
- 녹음 타이머 (MM:SS)
- 종료 버튼 (빨간 원형)

### 3. Processing Screen
- 단계별 진행 표시
- Step 0: Whisper STT (음성 → 텍스트)
- Step 1: LLM 엔진 (회의록 생성)
- Step 2: Notion 저장 (조건부)

### 4. Minutes Screen
- 탭 1: 회의록 (마크다운)
- 탭 2: 원본 스크립트
- Notion 저장 버튼 (수동)
- "추가 작업 요청" 버튼

### 5. Chat Screen
- 빠른 옵션: 액션아이템 추출, 영문 요약, 임원 보고용
- 자유 입력 메시지 필드
- 실시간 채팅 UI

### 6. Settings Screen
- OpenAI API 키 입력
- LLM 엔진 선택 (GPT/Gemma)
- Notion API 토큰 입력
- 저장 페이지 URL 입력
- 자동 저장 토글
- 회의록 작성 지침 입력
- 모델 정보/캐시 관리 (Gemma)

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
처리 화면 (Step 0: Whisper STT)
↓
Whisper API → transcript (원본 스크립트)
↓
처리 화면 (Step 1: LLM 엔진)
↓
LLM 엔진 선택에 따라 분기:
├─ OpenAI GPT → {title, minutes}
└─ Gemma → {title, minutes}
↓
[자동 저장 ON?]
├─ YES → 처리 화면 (Step 2: Notion)
│   ↓
│   Notion API → notionPageId 저장
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
LLM 엔진에 따라 분기:
├─ OpenAI GPT: OpenAiLlmService.processQuery()
└─ Gemma: GemmaInferenceService.processQuery()
↓
LLM 응답
↓
채팅 메시지 추가
```

## 🔍 파일 구조

```
meeting-assistant/
├── CLAUDE.md # 개발자용 오케스트레이터 지침
├── README.md # 이 파일 (사용자 가이드)
├── pubspec.yaml # 의존성
│
├── lib/
│   ├── main.dart # 앱 진입점 & 네비게이션
│   ├── models/
│   │   └── meeting.dart # Meeting, AppSettings, ChatMessage, RecordingState
│   ├── services/
│   │   ├── audio_recorder_service.dart # AAC 오디오 녹음
│   │   ├── whisper_api_service.dart # OpenAI Whisper API
│   │   ├── openai_llm_service.dart # OpenAI GPT 회의록/채팅
│   │   ├── gemma_inference_service.dart # Gemma 온디바이스
│   │   ├── notion_sync_service.dart # Notion API
│   │   └── app_settings_service.dart # 설정 영속화
│   ├── providers/
│   │   └── app_state.dart # Riverpod 프로바이더
│   └── screens/
│       ├── home_screen.dart
│       ├── recording_screen.dart
│       ├── processing_screen.dart
│       ├── minutes_screen.dart
│       ├── chat_screen.dart
│       └── settings_screen.dart
│
├── .github/workflows/
│   ├── build-apk.yml # PR/push → debug APK 빌드 + Slack
│   └── release.yml # v* 태그 → release APK + GitHub Release + Slack
│
├── scripts/
│   ├── monitor-ci.sh # GitHub API 폴링, 실패 시 Slack
│   └── deploy.sh # YAML 검증 + git push + 선택적 릴리즈 태그
│
└── docs/
    └── API.md # Notion API 참고
```

## 📌 상태 관리 (Riverpod)

### 주요 Providers

```dart
// 앱 설정
appSettingsProvider
├─ openaiApiKey: String?
├─ notionToken: String?
├─ notionPageUrl: String?
├─ autoSaveToNotion: bool
├─ minutesInstructions: String?
└─ useCloudLlm: bool  // true=GPT, false=Gemma

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

// LLM 상태 (Gemma)
llmStateProvider: LlmState
├─ needsDownload
├─ downloading
├─ loading
├─ ready
└─ error
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

# 출력: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (IPA)

```bash
# 릴리스 빌드
flutter build ios --release

# Xcode 에서 아카이브 및 배포
```

### GitHub Actions

```bash
# 디버그 빌드 (push to main/master, PR)
- compileSdk 35 패치
- flutter build apk --debug
- Artifacts 업로드 (14 일)
- Slack 알림

# 릴리스 빌드 (v* 태그)
- flutter build apk --release --split-per-abi
- app-arm64-v8a-release.apk 업로드
- GitHub Release 생성
- Slack 알림 (다운로드 링크)
```

## 📝 라이선스

MIT License

## 👨‍💻 개발자 정보

- **프로젝트**: Meeting Assistant
- **버전**: 1.0.0
- **플랫폼**: Flutter (Android + iOS)
- **마지막 업데이트**: 2026 년 5 월 24 일

## 📞 지원

문제가 발생하면:

1. 로그 확인 (`flutter logs`)
2. 캐시 삭제 (`flutter clean`)
3. 의존성 재설치 (`flutter pub get`)
4. 빌드 재실행 (`flutter pub run build_runner build`)

---

**상태**: 🟢 UI 화면 구현 완료 + 🟢 Whisper/OpenAI/Gemma 통합 완료 → 🟡 Notion 연동 구현 중
