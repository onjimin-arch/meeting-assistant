---
title: Meeting Assistant Flutter App - 오케스트레이터 지침
description: 온디바이스 AI 회의 자동 기록 & Notion 저장 모바일 앱 개발 오케스트레이터
---

# Meeting Assistant Flutter 앱 개발 지침

## 프로젝트 개요

**목표**: 플랫폼 내장 STT + Gemma 4 2B 온디바이스 파이프라인으로 회의 녹음 → 텍스트 변환 → 회의록 생성 → Notion 저장을 완전 자동화하는 Flutter 모바일 앱 구현

**기술 스택**:
- 프론트엔드: Flutter (Dart)
- STT: **플랫폼 내장 STT** — Android(SpeechRecognizer) / iOS(SFSpeechRecognizer), `speech_to_text` 패키지
- LLM: Gemma 4 2B (MediaPipe LLM Inference API)
- 로컬 DB: SQLite (drift ORM)
- 상태 관리: Riverpod
- Notion 연동: Notion REST API v1
- 플랫폼: Android APK + iOS IPA

**STT 아키텍처 결정 (Whisper Tiny → 플랫폼 STT 전환, 2026-05-13)**:
- 75MB Whisper Tiny 모델 다운로드 및 네이티브 FFI 통합 제거 → APK 경량화 & 첫 빌드부터 실제 동작
- 플랫폼 STT는 단일 세션 60초 한도가 있으므로 `PlatformSttService`가 세션을 자동 재시작하여
  회의처럼 긴 발화를 끊김 없이 수집 (사용자 입장에선 단일 세션처럼 보임)
- 오디오 파일은 저장하지 않음 (STT가 실시간으로 인식하므로). 재생 기능은 후속 단계에서
  flutter_sound를 활성화하여 별도 처리

---

## 구현 단계 (순서 준수 필수)

### 1단계: 프로젝트 스캐폴딩 ✅
- [x] pubspec.yaml 의존성 정의
- [x] 폴더 구조 생성 (`lib/`, `.claude/`)
- [x] 데이터 모델 정의 (`Meeting`, `AppSettings`, `ChatMessage`)
- [x] 기본 앱 구조 (main.dart)

### 2단계: 핵심 서비스 구현 ✅
- [x] PlatformSttService: 플랫폼 내장 STT로 실시간 음성 → 텍스트 (자동 세션 재시작)
- [x] GemmaInferenceService: 회의록 생성 및 채팅
- [x] NotionSyncService: Notion API 연동
- [x] AppSettingsService: 설정 영속화
- ⚠️ AudioRecorderService 및 WhisperSTTService 폐기 — 플랫폼 STT가 두 역할 모두 대체

### 3단계: 상태 관리 (Riverpod) ✅
- [x] appSettingsProvider: 앱 설정 상태
- [x] recordingStateProvider: 녹음 상태 (idle/recording/processing/completed/error)
- [x] currentMeetingProvider: 현재 회의 데이터
- [x] processingStepProvider: 처리 진행 상태 (0-3)
- [x] chatMessagesProvider: 채팅 메시지 목록

### 4단계: UI 화면 구현 ✅
- [x] HomeScreen: 회의 목록 + 새 녹음 버튼
- [x] RecordingScreen: 실시간 웨이브폼 + 타이머
- [x] ProcessingScreen: 단계별 진행 표시
- [x] MinutesScreen: 원본 스크립트 + 회의록 표시
- [x] ChatScreen: 추가 작업 요청 채팅
- [x] SettingsScreen: Notion 설정 + 자동 저장 토글

### 5단계: 네이티브 통합 (AI 파이프라인) 🔄
- [x] STT: 플랫폼 내장 STT (speech_to_text) — 별도 모델/FFI 불필요
- [ ] **ai-pipeline 서브에이전트 호출 필요** (이제 Gemma만 담당)
  - MediaPipe LLM Inference API Android/iOS 네이티브 설정
  - Gemma 2B 모델 다운로드 관리 (첫 실행 시)
  - 추론 호출 프로토콜 정의

### 6단계: Notion 연동 구현 🔄
- [ ] **notion-integration 서브에이전트 호출 필요**
  - Notion REST API v1 인증 (Bearer Token)
  - 마크다운 → Notion 블록 변환
  - 페이지 생성 및 에러 처리

### 7단계: 데이터베이스 통합
- [ ] SQLite (drift) 스키마 정의
- [ ] 회의 CRUD 연산
- [ ] 로컬 저장 및 조회

### 8단계: 통합 테스트 & 최적화
- [ ] E2E 플로우 테스트 (녹음 → 처리 → 저장)
- [ ] UI/UX 검증
- [ ] 성능 프로파일링 (메모리, CPU)

---

## 워크플로우: 메인 플로우 (홈 → 녹음 → 처리 → 회의록)

```
[HomeScreen]
    ↓
[녹음 버튼 탭] → PlatformSttService.startListening()  (마이크 권한 요청 + STT 세션 시작)
    ↓
[RecordingScreen]  ← STT가 백그라운드에서 실시간 인식 + 세션 자동 재시작
    ↓
[녹음 중단 버튼] → PlatformSttService.stopListening() → 누적된 transcript 반환
    ↓
[ProcessingScreen] (step: 0)  ← STT는 이미 완료, UI 표시만
    ↓
[Step 1: 회의록 생성] → GemmaInferenceService.generateMinutes(transcript) → {title, minutes}
    ↓
[ProcessingScreen] (step: 1) — 자동 저장 ON일 때만
    ↓
[Step 2: Notion (조건부)] → NotionSyncService.saveMinutesToNotion() → notionPageId
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
[GemmaInferenceService.processQuery(query, transcript, minutes)]
    ↓
[LLM 응답 반환]
    ↓
[ChatMessage 추가 및 화면 갱신]
```

---

## 서브에이전트 호출 시점

### ai-pipeline 에이전트
**언제**: 4단계 완료 후 (UI 화면이 완성되고, STT/LLM 서비스 stub이 준비된 후)

**입력**:
- MediaPipe LLM Inference API 공식 가이드
- Gemma 2B 모델 다운로드 URL (HuggingFace, Google MediaPipe)

**역할** (STT 부분은 플랫폼 STT로 대체되어 제외):
- MediaPipe LLM Inference Android/iOS 네이티브 설정
- Gemma 2B 모델 로딩, 캐싱, 에러 처리 구현
- GemmaInferenceService 실제 구현

**산출물**:
- `lib/services/gemma_inference_service.dart` (실제 구현)
- `lib/utils/model_downloader.dart` (Gemma 모델 다운로드 관리 — Whisper용 다운로드는 제거됨)

### notion-integration 에이전트
**언제**: 4단계 완료 후 (UI 화면 & 데이터 모델 준비 후)

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
  String? notionToken;          // Notion API 토큰
  String? notionPageUrl;        // 저장 부모 페이지 URL
  bool autoSaveToNotion;        // 자동 저장 여부 (기본값: false)
  String? minutesInstructions;  // 회의록 작성 지침
}
```

### RecordingState enum

```dart
enum RecordingState {
  idle,       // 초기
  recording,  // 녹음 중
  processing, // STT/Gemma/Notion 처리 중
  completed,  // 완료 (MinutesScreen 진입)
  error,      // 에러 발생
}
```

---

## 스킬 정의 (나중에 작성할 것)

| 스킬명 | 파일 | 역할 |
|--------|------|------|
| `platform-stt` | `.claude/skills/platform-stt/SKILL.md` | speech_to_text 사용, 세션 자동 재시작 |
| `gemma-inference` | `.claude/skills/gemma-inference/SKILL.md` | Gemma 추론, 프롬프트 템플릿 |
| `notion-sync` | `.claude/skills/notion-sync/SKILL.md` | Notion API 호출, 페이지 생성 |

---

## 금지 사항 ⛔

1. **서브에이전트 간 직접 호출 금지**: ai-pipeline ↔ notion-integration 직접 통신 X
   → 모든 데이터는 오케스트레이터 (CLAUDE.md) 경유

2. **API 키 하드코딩 금지**: 모든 Notion 토큰 → SharedPreferences 또는 환경 변수

3. **단일 에이전트에서 전체 AI 파이프라인 구현 금지**: STT(플랫폼 내장) + Gemma는 분리
   → ai-pipeline 에이전트는 Gemma만 담당. STT는 이미 PlatformSttService로 완결됨

4. **UI와 AI 통합 동시 구현 금지**: UI는 메인 오케스트레이터, AI는 서브에이전트

---

## 테스트 전략

### 1. 단위 테스트
- `PlatformSttService`: 세션 자동 재시작 시 partial → finalize 합산 검증
- `GemmaInferenceService`: 프롬프트 구성 및 응답 파싱
- `NotionSyncService`: API payload 구성 검증

### 2. 통합 테스트
- 전체 플로우: 녹음 → STT → Gemma → (선택) Notion → 저장
- 채팅 흐름: 질문 → Gemma 응답 → 메시지 표시
- 설정 변경 후 효과 (자동 저장 토글)

### 3. UI 테스트
- 상태 전이에 따른 화면 전환 검증
- 웹폼포 애니메이션 부드러움 확인
- 진행 상태 표시 정확성

---

## 파일 구조 (최종)

```
meeting-assistant/
├── CLAUDE.md                           # 이 파일 (오케스트레이터)
├── pubspec.yaml
├── lib/
│   ├── main.dart                       # 앱 진입점 & 라우팅
│   ├── models/
│   │   └── meeting.dart                # Meeting, AppSettings, ChatMessage
│   ├── services/
│   │   ├── platform_stt_service.dart    # 플랫폼 내장 STT (Whisper 대체)
│   │   ├── gemma_inference_service.dart # → ai-pipeline 에이전트
│   │   ├── notion_sync_service.dart     # → notion-integration 에이전트
│   │   └── app_settings_service.dart
│   ├── providers/
│   │   └── app_state.dart              # Riverpod 프로바이더
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── recording_screen.dart
│   │   ├── processing_screen.dart
│   │   ├── minutes_screen.dart
│   │   ├── chat_screen.dart
│   │   └── settings_screen.dart
│   └── utils/
│       ├── model_downloader.dart       # (ai-pipeline 작성)
│       └── notion_block_converter.dart # (notion-integration 작성)
├── .claude/
│   ├── skills/
│   │   ├── platform-stt/SKILL.md
│   │   ├── gemma-inference/SKILL.md
│   │   └── notion-sync/SKILL.md
│   └── agents/
│       ├── ai-pipeline.md              # (작성 예정)
│       └── notion-integration.md       # (작성 예정)
├── assets/
│   └── models/                         # 모델 저장 디렉토리 (런타임)
└── docs/
    ├── API.md                          # Notion API 참고
    └── MODELS.md                       # 모델 스펙 참고
```

---

## 체크리스트

- [x] 프로젝트 스캐폴딩
- [x] 데이터 모델 & 서비스
- [x] Riverpod 프로바이더
- [x] UI 화면 6개
- [ ] AI 파이프라인 네이티브 통합 (ai-pipeline 에이전트)
- [ ] Notion API 구현 (notion-integration 에이전트)
- [ ] SQLite 데이터베이스 통합
- [ ] 통합 테스트
- [ ] 성능 최적화
- [ ] 앱 배포 준비 (APK/IPA)

---

**마지막 업데이트**: 2026년 5월 13일
**상태**: 4단계 완료(UI) + STT 통합 완료(플랫폼 내장으로 전환) → 5단계 잔여(Gemma만) 준비 중
