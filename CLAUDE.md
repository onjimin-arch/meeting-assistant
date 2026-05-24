---
title: Meeting Assistant Flutter App - 오케스트레이터 지침
description: AI 기반 회의 자동 기록 & Notion 저장 모바일 앱 개발 오케스트레이터
---

# Meeting Assistant Flutter 앱 개발 지침

## 프로젝트 개요

**목표**: 오디오 녹음 → OpenAI Whisper API 로 음성 → 텍스트 변환 → OpenAI GPT 또는 Gemma 온디바이스 LLM 으로 회의록 생성 → Notion 저장을 자동화하는 Flutter 모바일 앱 구현

**기술 스탁**:
- 프론트엔드: Flutter (Dart)
- 오디오 녹음: `record` 패키지 (AAC-LC, 128kbps, 44.1kHz)
- STT: **OpenAI Whisper API** — 클라우드 기반 높은 정확도 음성 인식
- LLM (선택):
  - **OpenAI GPT** (클라우드): `gpt-4o-mini` — 정확한 회의록 생성
  - **Gemma 3 1B** (온디바이스): `flutter_gemma` — 오프라인 동작, 프라이버시 우위
- 로컬 DB: SharedPreferences (설정 + 회의 목록 JSON)
- 상태 관리: Riverpod
- Notion 연동: Notion REST API v1
- 플랫폼: Android APK + iOS IPA

**아키텍처 결정 (2026-05-24)**:
- STT: OpenAI Whisper API 사용 (정확도 우선)
- LLM: 사용자가 설정에서 선택 가능 (OpenAI GPT 또는 Gemma 온디바이스)
- `useCloudLlm` 설정으로 동적 전환 — 재시작 없이 즉시 적용
- 오디오 파일: Whisper API 전송 후 자동 삭제

---

## 구현 단계 (순서 준수 필수)

### 1 단계: 프로젝트 스캐폴딩 ✅
- [x] pubspec.yaml 의존성 정의
- [x] 폴더 구조 생성 (`lib/`, `.claude/`)
- [x] 데이터 모델 정의 (`Meeting`, `AppSettings`, `ChatMessage`)
- [x] 기본 앱 구조 (main.dart)

### 2 단계: 핵심 서비스 구현 ✅
- [x] AudioRecorderService: AAC 오디오 녹음
- [x] WhisperApiService: OpenAI Whisper API 호출
- [x] OpenAiLlmService: OpenAI GPT 회의록/채팅 생성
- [x] GemmaInferenceService: Gemma 온디바이스 회의록/채팅 생성
- [x] NotionSyncService: Notion API 연동
- [x] AppSettingsService: 설정 영속화
- [x] MeetingRepository: 회의 목록 JSON 저장

### 3 단계: 상태 관리 (Riverpod) ✅
- [x] appSettingsProvider: 앱 설정 상태
- [x] recordingStateProvider: 녹음 상태 (idle/recording/processing/completed/error)
- [x] currentMeetingProvider: 현재 회의 데이터
- [x] processingStepProvider: 처리 진행 상태 (0-3)
- [x] chatMessagesProvider: 채팅 메시지 목록
- [x] llmStateProvider: LLM 엔진 상태 (Gemma 모델 준비 상태)

### 4 단계: UI 화면 구현 ✅
- [x] HomeScreen: 회의 목록 + 새 녹음 버튼
- [x] RecordingScreen: 실시간 웨이브폼 + 타이머
- [x] ProcessingScreen: 단계별 진행 표시
- [x] MinutesScreen: 원본 스크립트 + 회의록 표시
- [x] ChatScreen: 추가 작업 요청 채팅
- [x] SettingsScreen: OpenAI/Notion 설정 + LLM 엔진 선택

### 5 단계: Notion 연동 구현 🔄
- [ ] **notion-integration 서브에이전트 호출 필요**
- Notion REST API v1 인증 (Bearer Token)
- 마크다운 → Notion 블록 변환
- 페이지 생성 및 에러 처리

### 6 단계: 데이터베이스 통합
- [ ] SQLite (drift) 스키마 정의
- [ ] 회의 CRUD 연산
- [ ] 로컬 저장 및 조회

### 7 단계: 통합 테스트 & 최적화
- [ ] E2E 플로우 테스트 (녹음 → 처리 → 저장)
- [ ] UI/UX 검증
- [ ] 성능 프로파일링 (메모리, CPU)

---

## 워크플로우: 메인 플로우 (홈 → 녹음 → 처리 → 회의록)

```
[HomeScreen]
↓
[녹음 버튼 탭] → AudioRecorderService.startRecording() (마이크 권한 요청)
↓
[RecordingScreen] ← AAC 오디오 녹음 중 (웨이브폼 + 타이머)
↓
[녹음 중단 버튼] → AudioRecorderService.stopRecording() → audioPath 반환
↓
[ProcessingScreen] (step: 0)
↓
[Step 0: Whisper STT] → WhisperApiService.transcribe(audioPath) → transcript
↓
[Step 1: 회의록 생성] → LLM 엔진 선택에 따라 분기
├─ OpenAI GPT: OpenAiLlmService.generateMinutes(transcript)
└─ Gemma: GemmaInferenceService.generateMinutes(transcript)
→ {title, minutes}
↓
[Step 2: Notion (조건부)] → autoSaveToNotion == true 일 때만
→ NotionSyncService.saveMinutesToNotion() → notionPageId
↓
[MinutesScreen] (회의 데이터 표시)
↓
[추가 작업 채팅] ← ChatScreen
```

---

## 워크플로우: 추가 작업 플로우 (채팅)

```
[MinutesScreen "추가 작업 요청" 버튼]
↓
[ChatScreen]
↓
[사용자 입력 또는 빠른 옵션 선택]
↓
LLM 엔진 선택에 따라 분기:
├─ OpenAI GPT: OpenAiLlmService.processQuery(query, transcript, minutes)
└─ Gemma: GemmaInferenceService.processQuery(query, transcript, minutes)
↓
[LLM 응답 반환]
↓
[ChatMessage 추가 및 화면 갱신]
```

---

## 서브에이전트 호출 시점

### notion-integration 에이전트
**언제**: 4 단계 완료 후 (UI 화면 & 데이터 모델 준비 후)

**입력**:
- Notion REST API v1 공식 문서
- Meeting 모델 구조
- 회의록 마크다운 샘플

**역할**:
- Notion 페이지 생성 payload 구성
- 마크다운 텍스트 → Notion 블록 변환기 (제목, 단락, 리스트 등)
- API 인증 및 에러 처리 (네트워크 오류, 유효성 검사)
- NotionSyncService 실제 구현

**산출물**:
- `lib/services/notion_sync_service.dart` (실제 구현)
- `lib/utils/notion_block_converter.dart` (마크다운 변환)

---

## 주요 설정 항목

### AppSettings (설정 화면에서 관리)

```dart
class AppSettings {
  String? openaiApiKey;      // OpenAI API 키 (Whisper STT + GPT LLM)
  String? notionToken;       // Notion API 토큰
  String? notionPageUrl;     // 저장 부모 페이지 URL
  bool autoSaveToNotion;     // 자동 저장 여부 (기본값: false)
  String? minutesInstructions; // 회의록 작성 지침
  bool useCloudLlm;          // true=OpenAI GPT, false=Gemma 온디바이스
}
```

### RecordingState enum

```dart
enum RecordingState {
  idle,        // 초기
  recording,   // 녹음 중
  processing,  // STT/Gemma/Notion 처리 중
  completed,   // 완료 (MinutesScreen 진입)
  error,       // 에러 발생
}
```

---

## 스킬 정의 (나중에 작성할 것)

| 스킬명 | 파일 | 역할 |
|--------|------|------|
| `audio-recorder` | `.claude/skills/audio-recorder/SKILL.md` | record 패키지, AAC 녹음 |
| `whisper-stt` | `.claude/skills/whisper-stt/SKILL.md` | OpenAI Whisper API 호출 |
| `openai-llm` | `.claude/skills/openai-llm/SKILL.md` | OpenAI GPT 회의록/채팅 |
| `gemma-inference` | `.claude/skills/gemma-inference/SKILL.md` | Gemma 온디바이스 추론 |
| `notion-sync` | `.claude/skills/notion-sync/SKILL.md` | Notion API 호출, 페이지 생성 |

---

## 금지 사항 ⛔

1. **서브에이전트 간 직접 호출 금지**: notion-integration ↔ 다른 서비스 직접 통신 X
   → 모든 데이터는 오케스트레이터 (CLAUDE.md) 경유

2. **API 키 하드코딩 금지**: 모든 API 키 → SharedPreferences 또는 환경 변수

3. **민감 정보 노추 금지**: API 키, 토큰 등 절대 코드에 하드코딩 금지

4. **UI 와 AI 통합 동시 구현 금지**: UI 는 메인 오케스트레이터, AI 는 서브에이전트

---

## 테스트 전략

### 1. 단위 테스트
- `WhisperApiService`: multipart POST, 에러 처리
- `OpenAiLlmService`: 프롬프트 구성, 응답 파싱
- `GemmaInferenceService`: 모델 준비 상태, 프롬프트 구성
- `NotionSyncService`: API payload 구성 검증

### 2. 통합 테스트
- 전체 플로우: 녹음 → Whisper STT → LLM → (선택) Notion → 저장
- 채팅 흐름: 질문 → LLM 응답 → 메시지 표시
- 설정 변경 후 효과 (useCloudLlm 토글)

### 3. UI 테스트
- 상태 전이에 따른 화면 전환 검증
- 웨이브폼 애니메이션 부드러움 확인
- 진행 상태 표시 정확성

---

## 파일 구조 (최종)

```
meeting-assistant/
├── CLAUDE.md # 이 파일 (오케스트레이터)
├── README.md # 사용자용 가이드
├── pubspec.yaml
├── lib/
│   ├── main.dart # 앱 진입점 & 라우팅
│   ├── models/
│   │   └── meeting.dart # Meeting, AppSettings, ChatMessage
│   ├── services/
│   │   ├── audio_recorder_service.dart # AAC 오디오 녹음
│   │   ├── whisper_api_service.dart # Whisper STT
│   │   ├── openai_llm_service.dart # OpenAI GPT 회의록/채팅
│   │   ├── gemma_inference_service.dart # Gemma 온디바이스
│   │   ├── notion_sync_service.dart # Notion 연동
│   │   └── app_settings_service.dart # 설정 영속화
│   ├── providers/
│   │   └── app_state.dart # Riverpod 프로바이더
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── recording_screen.dart
│   │   ├── processing_screen.dart
│   │   ├── minutes_screen.dart
│   │   ├── chat_screen.dart
│   │   └── settings_screen.dart
│   └── utils/
│       └── notion_block_converter.dart # (notion-integration 작성)
├── .claude/
│   ├── skills/
│   │   ├── audio-recorder/SKILL.md
│   │   ├── whisper-stt/SKILL.md
│   │   ├── openai-llm/SKILL.md
│   │   ├── gemma-inference/SKILL.md
│   │   └── notion-sync/SKILL.md
│   └── agents/
│       └── notion-integration.md # (작성 예정)
├── .github/
│   └── workflows/
│       ├── build-apk.yml # PR/push → debug APK 빌드 + Slack
│       └── release.yml # v* 태그 → release APK + GitHub Release + Slack
├── scripts/
│   ├── monitor-ci.sh # GitHub API 폴링, 실패 시 Slack
│   └── deploy.sh # YAML 검증 + git push + 선택적 릴리즈 태그
└── docs/
    └── API.md # Notion API 참고
```

---

## 체크리스트

- [x] 프로젝트 스캐폴딩
- [x] 데이터 모델 & 서비스
- [x] Riverpod 프로바이더
- [x] UI 화면 6 개
- [x] Whisper STT 통합
- [x] OpenAI GPT 통합
- [x] Gemma 온디바이스 통합
- [ ] Notion API 구현 (notion-integration 에이전트)
- [ ] SQLite 데이터베이스 통합
- [ ] 통합 테스트
- [ ] 성능 최적화
- [ ] 앱 배포 준비 (APK/IPA)

---

**마지막 업데이트**: 2026 년 5 월 24 일
**상태**: 4 단계 완료 (UI) + Whisper/OpenAI/Gemma 통합 완료 → Notion 연동 준비 중
**LLM 엔진**: 사용자 선택 (OpenAI GPT 또는 Gemma 온디바이스)
