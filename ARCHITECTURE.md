# Meeting Assistant — 아키텍처 & 기능 상세 문서

> 최종 업데이트: 2026-05-24  
> 버전: 1.x (OpenAI Whisper + Gemma 3 1B 파이프라인)

---

## 목차

1. [앱 개요](#1-앱-개요)
2. [기능 목록](#2-기능-목록)
3. [기술 스택](#3-기술-스택)
4. [파일 구조](#4-파일-구조)
5. [핵심 파이프라인](#5-핵심-파이프라인)
   - 5-1. 녹음 → Whisper STT
   - 5-2. 회의록 생성 (Gemma)
   - 5-3. Notion 저장
   - 5-4. 후속 채팅
6. [화면 흐름 (Screen Flow)](#6-화면-흐름-screen-flow)
7. [데이터 모델](#7-데이터-모델)
8. [상태 관리 (Riverpod)](#8-상태-관리-riverpod)
9. [서비스 레이어](#9-서비스-레이어)
10. [로컬 저장소](#10-로컬-저장소)
11. [LLM 모델 관리](#11-llm-모델-관리)
12. [CI/CD 파이프라인](#12-cicd-파이프라인)
13. [Android 빌드 설정](#13-android-빌드-설정)
14. [설정 항목 전체 목록](#14-설정-항목-전체-목록)

---

## 1. 앱 개요

Meeting Assistant는 회의를 **녹음 → 텍스트 변환 → 회의록 자동 생성 → Notion 저장**하는 Android/iOS 모바일 앱이다.

```
녹음 (m4a)
    │
    ▼
OpenAI Whisper API          ← 클라우드 STT (한국어 최적화)
    │  transcript (텍스트)
    ▼
Gemma 3 1B (온디바이스)     ← 회의록 생성, 채팅 응답
    │  {title, minutes}
    ▼
Notion REST API             ← 선택적 자동 저장
    │
    ▼
SharedPreferences           ← 로컬 영속화
```

**설계 원칙**
- STT는 클라우드(Whisper), LLM은 온디바이스(Gemma) — 정확도와 프라이버시 균형
- 첫 실행 시 Gemma 모델 1회 다운로드(~530MB), 이후 오프라인 LLM 동작
- APK 자체에 AI 모델 미포함 → 앱 크기 경량화

---

## 2. 기능 목록

### 핵심 기능
| 기능 | 설명 |
|------|------|
| **회의 녹음** | m4a(AAC) 포맷으로 오디오 파일 저장, 타이머 + 웨이브폼 표시 |
| **Whisper STT** | OpenAI Whisper API로 한국어 음성 → 텍스트 변환 |
| **회의록 생성** | Gemma 3 1B 온디바이스 LLM으로 구조화된 회의록 자동 작성 |
| **Notion 자동 저장** | 완성된 회의록을 Notion 페이지에 마크다운 블록으로 업로드 |
| **후속 채팅** | 회의록 기반으로 Gemma와 추가 질의응답 |
| **회의 목록** | 저장된 회의 조회, 탭으로 열기, 길게 눌러 삭제 |

### 부가 기능
| 기능 | 설명 |
|------|------|
| **원본 스크립트 보기** | 회의록과 함께 STT 원문 탭 제공 |
| **Notion 수동 저장** | 자동 저장 OFF 상태에서 회의록 화면에서 직접 저장 |
| **회의록 작성 지침** | 사용자가 Gemma에 전달할 추가 프롬프트 설정 가능 |
| **LLM 모델 다운로드 관리** | SHA-256 검증, 재다운로드, 캐시 삭제 |

---

## 3. 기술 스택

| 구분 | 기술 | 버전 | 역할 |
|------|------|------|------|
| UI 프레임워크 | Flutter | stable | 크로스플랫폼 UI |
| 언어 | Dart | ≥3.0 | 앱 로직 전체 |
| 상태 관리 | flutter_riverpod | ^2.5.1 | 앱 전역 상태 |
| 오디오 녹음 | record | ^5.2.0 | m4a(AAC-LC) 파일 녹음 |
| STT | OpenAI Whisper API | whisper-1 | 음성 → 텍스트 (클라우드) |
| LLM | flutter_gemma | ^0.10.0 | Gemma 3 1B 온디바이스 추론 |
| LLM 런타임 | MediaPipe LLM Inference | — | .task 포맷 모델 실행 |
| HTTP | http | ^1.2.1 | Whisper API, Notion API, 모델 다운로드 |
| 해시 검증 | crypto | ^3.0.3 | SHA-256 모델 무결성 검증 |
| 로컬 저장 | shared_preferences | ^2.2.3 | 설정 + 회의 목록 JSON |
| 날짜 포맷 | intl | ^0.19.0 | 날짜/시간 표시 |
| UUID | uuid | ^4.4.0 | 회의 ID 생성 |
| 경로 | path_provider + path | ^2.1.3 / ^1.9.0 | 파일 시스템 경로 |
| 권한 | permission_handler | ^11.3.1 | 마이크 권한 요청 |

### 빌드 환경
| 항목 | 값 |
|------|----|
| Java | 17 (Temurin) |
| Android compileSdk | 34 |
| Android minSdk | 24 (Android 7.0) |
| Android targetSdk | 34 |
| Flutter channel | stable |
| CI 환경 | ubuntu-latest (GitHub Actions) |

---

## 4. 파일 구조

```
meeting-assistant/
├── lib/
│   ├── main.dart                        # 앱 진입점, 화면 라우팅, 녹음 파이프라인 조율
│   ├── models/
│   │   └── meeting.dart                 # Meeting, AppSettings, ChatMessage 데이터 모델
│   ├── providers/
│   │   └── app_state.dart               # Riverpod 프로바이더 전체 (설정/LLM/회의/채팅)
│   ├── screens/
│   │   ├── home_screen.dart             # 회의 목록 + 새 녹음 버튼
│   │   ├── recording_screen.dart        # 녹음 중 UI (웨이브폼, 타이머, 중지 버튼)
│   │   ├── processing_screen.dart       # 처리 단계 표시 (Whisper → Gemma → Notion)
│   │   ├── minutes_screen.dart          # 회의록 + 원본 스크립트 탭
│   │   ├── chat_screen.dart             # 회의 기반 후속 채팅
│   │   └── settings_screen.dart         # 설정 (OpenAI 키, Notion 연동, 회의록 지침)
│   ├── services/
│   │   ├── audio_recorder_service.dart  # m4a 오디오 녹음 (record 패키지 래퍼)
│   │   ├── whisper_api_service.dart     # OpenAI Whisper API multipart POST
│   │   ├── gemma_inference_service.dart # Gemma 모델 로드 + 회의록/채팅 추론
│   │   ├── notion_sync_service.dart     # Notion REST API v1 연동 + 마크다운 변환
│   │   ├── app_settings_service.dart    # SharedPreferences 설정 로드/저장
│   │   ├── meeting_repository.dart      # 회의 목록 JSON 영속화
│   │   └── platform_stt_service.dart    # (레거시) 플랫폼 내장 STT — 미사용
│   └── utils/
│       └── model_downloader.dart        # Gemma 모델 다운로드, 캐싱, SHA-256 검증
├── android/
│   └── app/
│       └── build.gradle.kts             # compileSdk=34, minSdk=24, Java 17, 서명 설정
├── .github/
│   └── workflows/
│       ├── build-apk.yml                # PR/push → debug APK 빌드 + Slack 알림
│       └── release.yml                  # v* 태그 → arm64 release APK + GitHub Release + Slack
├── scripts/
│   ├── monitor-ci.sh                    # GitHub API 폴링, 실패 시 Slack 알림
│   └── deploy.sh                        # YAML 검증 + git push + 선택적 릴리즈 태그
├── ARCHITECTURE.md                      # 이 파일
├── CLAUDE.md                            # Claude Code 에이전트 지침
└── pubspec.yaml
```

---

## 5. 핵심 파이프라인

### 5-1. 녹음 → Whisper STT

```
[사용자: 녹음 버튼 탭]
        │
        ▼
  LLM 준비 상태 확인 (llmStateProvider)
  ┌────────────────────────────────────┐
  │ needsDownload → 다운로드 다이얼로그 │
  │ loading       → 로딩 대기 다이얼로그│
  │ error         → 재시도 다이얼로그   │
  │ ready         → 바로 진행          │
  └────────────────────────────────────┘
        │
        ▼
  AudioRecorderService.startRecording()
  - RecordConfig: AAC-LC, 128kbps, 44.1kHz
  - 저장 경로: {앱 Documents}/recordings/{timestamp}.m4a
  - recordingState → RecordingState.recording
        │
        ▼
  [RecordingScreen 표시] ← 타이머 + 가짜 웨이브폼 애니메이션
        │
  [사용자: 중지 버튼 탭]
        │
        ▼
  AudioRecorderService.stopRecording()
  → audioPath: String? (m4a 파일 경로)
        │
        ▼
  OpenAI API 키 확인 (appSettingsProvider.openaiApiKey)
  ┌──────────────────────────────────────────────────┐
  │ null/empty → SnackBar("API 키 미설정") + 중단    │
  └──────────────────────────────────────────────────┘
        │
        ▼
  processingStep → 0 (ProcessingScreen 표시: "음성 파일 변환 중")
        │
        ▼
  WhisperApiService.transcribe(audioPath, apiKey)
  ┌──────────────────────────────────────────────────────────────┐
  │  POST https://api.openai.com/v1/audio/transcriptions         │
  │  Headers: Authorization: Bearer {apiKey}                      │
  │  Body (multipart/form-data):                                  │
  │    - file: m4a 파일 바이너리                                  │
  │    - model: "whisper-1"                                       │
  │    - language: "ko"                                           │
  │    - response_format: "text"                                  │
  │  Timeout: 5분                                                 │
  │  성공: response.body (plain text transcript)                  │
  │  실패: HTTP status + error.message 포함 Exception             │
  └──────────────────────────────────────────────────────────────┘
        │
        ▼
  File(audioPath).delete()  ← 임시 녹음 파일 정리
        │
        ▼
  → transcript 전달 → Gemma 단계로
```

### 5-2. 회의록 생성 (Gemma)

```
  processingStep → 1 (ProcessingScreen: "회의록 생성 중")
        │
        ▼
  GemmaInferenceService.generateMinutes(transcript, instructions?)
  ┌──────────────────────────────────────────────────────────────┐
  │ 1. transcript 길이 검증 (최소 50자, 미달 시 ArgumentError)    │
  │ 2. 프롬프트 조립:                                             │
  │    - 규칙: TITLE: 첫 줄, 마크다운 본문                        │
  │    - 항목: 일시, 참석자, 주요 안건, 결정사항, 액션아이템       │
  │    - 환각 금지: 원본에 없는 사실 생성 금지                    │
  │    - 사용자 추가 지침 (minutesInstructions) 병합              │
  │ 3. createSession(temperature=0.3, topK=40, maxTokens=2048)   │
  │ 4. session.addQueryChunk(prompt)                              │
  │ 5. session.getResponse() → raw response                      │
  │ 6. session.close()                                            │
  └──────────────────────────────────────────────────────────────┘
        │
        ▼
  _parseMinutesResponse(response)
  ┌─────────────────────────────────────────────────────────────┐
  │ 첫 줄에 "TITLE: ..." 또는 "제목: ..." 패턴 → title 추출    │
  │ 나머지 줄 → minutes 본문                                     │
  │ 파싱 실패 시 fallback: title="회의록", body=전체 response    │
  └─────────────────────────────────────────────────────────────┘
        │
        ▼
  → {title, minutes} 반환
```

**Gemma 프롬프트 구조**
```
다음은 회의를 음성 인식으로 받아쓴 원본 텍스트입니다...

[규칙]
- 첫 줄에 회의 제목 1줄만 (예: "TITLE: 2025 Q2 전략 회의")
- 본문: 일시(추정), 참석자, 주요 안건, 결정사항, 액션 아이템(담당자/기한)
- 절대 환각 금지: 원본에 없는 내용 생성 금지
- 모호한 부분은 "(불명확)" 표기
- 한국어로 작성

[추가 작성 지침]   ← minutesInstructions가 있을 때만 포함
{사용자 지침}

[원본 transcript]
{transcript}

위 규칙대로 작성:
```

### 5-3. Notion 저장

```
  autoSaveToNotion == true && minutesSuccess == true
        │
        ▼
  processingStep → 2 (ProcessingScreen: "Notion에 저장 중")
        │
        ▼
  NotionSyncService.saveMinutesToNotion(title, minutes, dateTime)
  ┌──────────────────────────────────────────────────────────────┐
  │ 1. pageUrl에서 Notion 페이지 ID 추출                         │
  │    - UUID 형식(8-4-4-4-12) 파싱                              │
  │    - 32자리 hex → UUID 변환                                  │
  │ 2. minutes의 첫 번째 # 또는 ## 제목으로 effectiveTitle 추출  │
  │ 3. POST https://api.notion.com/v1/pages                      │
  │    Headers:                                                   │
  │      Authorization: Bearer {notionToken}                     │
  │      Notion-Version: 2022-06-28                              │
  │    parent type 순서: page_id → 404 시 database_id 재시도     │
  │ 4. 마크다운 → Notion 블록 변환 (최대 100개 children)         │
  │    # → heading_1, ## → heading_2, ### → heading_3            │
  │    - / * → bulleted_list_item                                │
  │    **텍스트** → bold annotation                              │
  │    나머지 → paragraph                                        │
  │ 5. 날짜 프로퍼티(날짜) 추가 (dateTime이 있을 때)             │
  └──────────────────────────────────────────────────────────────┘
        │
        ▼
  notionPageId (UUID) 반환 → Meeting 객체에 저장
```

### 5-4. 후속 채팅 (Gemma Chat)

```
  [MinutesScreen: "추가 작업 요청" 버튼]
        │
        ▼
  [ChatScreen] ← 회의록 + transcript 컨텍스트 보유
        │
  [사용자 메시지 입력 또는 빠른 옵션 선택]
        │
        ▼
  GemmaInferenceService.processQuery(query, transcript, minutes)
  ┌──────────────────────────────────────────────────────────────┐
  │ 프롬프트:                                                     │
  │   당신은 회의 보조 AI입니다.                                  │
  │   [회의 원본 transcript] ... [정리된 회의록] ... [사용자 요청]│
  │   createSession(temperature=0.5, randomSeed=랜덤, topK=40)   │
  └──────────────────────────────────────────────────────────────┘
        │
        ▼
  assistant 메시지로 chatMessagesProvider에 추가
```

---

## 6. 화면 흐름 (Screen Flow)

```
┌────────────────────────────────────────────────────────────────┐
│                        AppShell (main.dart)                    │
│    recordingState 값에 따라 어떤 화면을 빌드할지 결정          │
└─────────────────────────┬──────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────────┐
          │               │                   │
     idle/completed  recording            processing
          │               │                   │
          ▼               ▼                   ▼
   ┌────────────┐  ┌─────────────────┐  ┌──────────────────┐
   │ HomeScreen │  │ RecordingScreen │  │ ProcessingScreen │
   │            │  │                 │  │ step 0: Whisper  │
   │ 회의 목록  │  │ 웨이브폼 애니메  │  │ step 1: Gemma    │
   │ 녹음 버튼  │  │ 션 + 타이머     │  │ step 2: Notion   │
   │ 설정 아이콘│  │ 중지 버튼       │  │ (autoSave 시)    │
   └─────┬──────┘  └────────┬────────┘  └──────────────────┘
         │                  │
         │ 설정 버튼         │ 중지 탭
         ▼                  ▼
   ┌──────────────┐   완료 후 completed
   │ SettingsScreen│        │
   │               │        ▼
   │ OpenAI API 키 │  ┌──────────────────┐
   │ Notion 설정   │  │  MinutesScreen   │
   │ 회의록 지침   │  │  탭1: 회의록     │
   │ 모델 정보     │  │  탭2: 원본 스크립트│
   └──────────────┘  │  Notion 저장 버튼 │
                     └────────┬─────────┘
                              │ 추가 작업 버튼
                              ▼
                     ┌──────────────────┐
                     │   ChatScreen     │
                     │   회의 기반 Q&A  │
                     │   빠른 옵션 버튼 │
                     └──────────────────┘
```

### 화면별 상세

| 화면 | RecordingState | 주요 역할 |
|------|----------------|-----------|
| HomeScreen | idle | 회의 목록(최신순), 새 녹음, 설정 이동 |
| RecordingScreen | recording | 녹음 타이머, 웨이브폼, 중지 버튼 |
| ProcessingScreen | processing | 3단계 진행 표시 (step 0→1→2) |
| MinutesScreen | completed | 회의록/스크립트 탭, Notion 저장 |
| ChatScreen | (overlay) | Gemma 채팅, 채팅 메시지 목록 |
| SettingsScreen | (overlay) | 전체 설정 관리 |

---

## 7. 데이터 모델

### Meeting

```dart
class Meeting {
  final String id;           // millisecondsSinceEpoch 기반 고유 ID
  final String title;        // Gemma가 추출한 회의 제목
  final DateTime dateTime;   // 녹음 시작 시각
  final int duration;        // 녹음 길이 (초)
  final String transcript;   // Whisper STT 원문
  final String minutes;      // Gemma 생성 회의록 (마크다운)
  final String audioPath;    // 오디오 파일 경로 (삭제 후 빈 문자열)
  final String? instructions; // 사용 당시의 회의록 작성 지침
  final DateTime createdAt;  // 저장 시각
  final String? notionPageId; // Notion 저장 성공 시 페이지 UUID
  final bool notionSaved;    // Notion 저장 성공 여부
}
```

### AppSettings

```dart
class AppSettings {
  final String? openaiApiKey;      // OpenAI API 키 (Whisper STT)
  final String? notionToken;       // Notion Integration API 토큰
  final String? notionPageUrl;     // Notion 저장 대상 페이지 URL
  final bool autoSaveToNotion;     // 회의록 생성 직후 자동 저장 여부 (기본 false)
  final String? minutesInstructions; // Gemma 회의록 작성 추가 지침
}
```

### ChatMessage

```dart
class ChatMessage {
  final String role;       // 'user' 또는 'assistant'
  final String text;       // 메시지 내용
  final DateTime timestamp;
}
```

---

## 8. 상태 관리 (Riverpod)

모든 Riverpod 프로바이더는 `lib/providers/app_state.dart`에 집중.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Riverpod 프로바이더                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  appSettingsProvider (StateNotifierProvider<AppSettings>)        │
│  └─ AppSettingsNotifier                                          │
│     ├─ _init(): SharedPreferences에서 설정 로드                  │
│     ├─ updateSettings(AppSettings)                               │
│     ├─ updateNotionSettings(token, pageUrl)                      │
│     ├─ toggleAutoSave(bool)                                      │
│     └─ updateMinutesInstructions(String)                         │
│                                                                   │
│  llmStateProvider (StateNotifierProvider<LlmState>)              │
│  └─ LlmStateNotifier                                             │
│     ├─ _initialCheck(): 캐시 확인 → needsDownload or loading     │
│     ├─ downloadAndLoad(): 다운로드 + 모델 로드                   │
│     ├─ loadModelFromCache(): 캐시에서 직접 로드                  │
│     └─ deleteModel(): 캐시 삭제                                  │
│     LlmState { status, downloadProgress, downloadedBytes,        │
│                totalBytes, errorMessage }                        │
│     LlmReadiness: unknown → needsDownload → downloading          │
│                   → loading → ready / error                      │
│                                                                   │
│  meetingsProvider (StateNotifierProvider<List<Meeting>>)         │
│  └─ MeetingsNotifier                                             │
│     ├─ _load(): 앱 시작 시 전체 로드                             │
│     ├─ add(Meeting)                                              │
│     ├─ remove(id)                                                │
│     └─ updateOne(Meeting)                                        │
│                                                                   │
│  recordingStateProvider (StateProvider<RecordingState>)          │
│  └─ idle / recording / processing / completed / error            │
│                                                                   │
│  currentMeetingProvider (StateProvider<Meeting?>)                │
│  └─ 현재 열려있는 회의 (MinutesScreen, ChatScreen에서 사용)      │
│                                                                   │
│  processingStepProvider (StateProvider<int>)                     │
│  └─ 0: Whisper, 1: Gemma, 2: Notion                              │
│                                                                   │
│  chatMessagesProvider (StateNotifierProvider<List<ChatMessage>>) │
│  └─ ChatMessagesNotifier                                         │
│     ├─ addMessage(ChatMessage)                                   │
│     └─ clearMessages()                                           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. 서비스 레이어

### AudioRecorderService
```
역할: m4a 오디오 파일 녹음
의존: record 패키지 (AudioRecorder)

startRecording()
  - RecordConfig: encoder=aacLc, bitRate=128000, sampleRate=44100
  - 저장 경로: {getApplicationDocumentsDirectory()}/recordings/{ms}.m4a
  - 디렉토리 자동 생성

stopRecording() → String? (파일 경로)
  - AudioRecorder.stop() 호출
  - 경로 반환 후 내부 경로 초기화

hasPermission() → bool (마이크 권한 확인)
```

### WhisperApiService
```
역할: OpenAI Whisper API 호출로 텍스트 변환
의존: http 패키지

transcribe(audioPath, apiKey, language='ko') → String
  - MultipartRequest POST to /v1/audio/transcriptions
  - 파일 바이너리 첨부 (multipart)
  - model="whisper-1", language="ko", response_format="text"
  - Timeout: 5분
  - 성공: plain text 반환
  - 실패: HTTP status + API error message 포함 Exception
```

### GemmaInferenceService
```
역할: 온디바이스 Gemma 모델로 회의록 생성 + 채팅
의존: flutter_gemma 패키지 (MediaPipe LLM Inference)
패턴: 싱글톤 (_instance)

ensureReady(modelFilePath)
  - 같은 경로면 재로드 생략 (캐시)
  - FlutterGemmaPlugin → setModelPath → createModel
  - Backend: CPU (GPU는 일부 기기에서 OOM 위험)
  - maxTokens: 2048

generateMinutes(transcript, instructions?) → {title, minutes}
  - 최소 50자 검증
  - temperature=0.3 (결정론적 출력)
  - TITLE: 패턴 파싱

processQuery(query, transcript, minutes) → String
  - temperature=0.5 (다양한 응답)
  - 매 호출마다 랜덤 시드
```

### NotionSyncService
```
역할: 회의록을 Notion 페이지로 저장
의존: http 패키지

saveMinutesToNotion(title, minutes, dateTime) → pageId
  - page_id → 실패 시 database_id 순서로 parent type 시도
  - 마크다운 → Notion 블록 변환 (최대 100 children)
  - 날짜 프로퍼티 자동 설정

_markdownToNotionBlocks(markdown)
  - # → heading_1
  - ## → heading_2
  - ### → heading_3
  - -, * → bulleted_list_item
  - **text** → bold rich_text annotation
  - 나머지 → paragraph

_extractPageIdFromUrl(url)
  - UUID 형식 직접 파싱
  - 32자리 hex → 8-4-4-4-12 UUID 포맷 변환
```

### AppSettingsService
```
역할: 앱 설정 SharedPreferences 영속화
키 목록:
  - openai_api_key
  - notion_token
  - notion_page_url
  - auto_save_to_notion
  - minutes_instructions
```

### MeetingRepository
```
역할: 회의 목록 JSON 직렬화/역직렬화
저장소: SharedPreferences (키: meetings_v1)
포맷: JSON Array (List<Meeting.toJson()>)
정렬: 최신순 (insert(0, ...))

loadAll() → List<Meeting>
append(Meeting) → List<Meeting>   (맨 앞에 삽입)
remove(id) → List<Meeting>
update(Meeting) → List<Meeting>
clear()  (디버그용 전체 삭제)
```

---

## 10. 로컬 저장소

앱이 사용하는 로컬 저장소는 두 가지.

```
SharedPreferences
├── [설정]
│   ├── openai_api_key       → String
│   ├── notion_token         → String
│   ├── notion_page_url      → String
│   ├── auto_save_to_notion  → bool
│   └── minutes_instructions → String
└── [회의 목록]
    └── meetings_v1          → JSON String (List<Meeting>)

앱 파일 시스템 (getApplicationSupportDirectory)
└── models/
    └── gemma3-1b-it-int4.task   (~530MB, SHA-256 검증 후 영구 캐시)

앱 Documents 디렉토리 (getApplicationDocumentsDirectory)
└── recordings/
    └── {timestamp}.m4a     (녹음 직후 Whisper 전송 완료 시 자동 삭제)
```

> **주의**: 회의록 텍스트는 SharedPreferences에 JSON으로 저장되므로 데이터가 많아지면 성능 저하 가능. 향후 SQLite(drift)로 마이그레이션 예정.

---

## 11. LLM 모델 관리

### 기본 모델 정보
| 항목 | 값 |
|------|----|
| 모델명 | Gemma 3 1B Instruct |
| 양자화 | int4 (4-bit) |
| 포맷 | MediaPipe .task |
| 크기 | ~530MB |
| SHA-256 | `e3d981c01aeaaac69a84ffa0d4be13281b3176731063f1bea1c9fe6887bd9dee` |
| 호스팅 | GitHub Release (onjimin-arch/meeting-assistant, tag: models-v1) |
| 백엔드 | CPU (flutter_gemma PreferredBackend.cpu) |

### 모델 다운로드 흐름

```
앱 시작 → LlmStateNotifier._initialCheck()
              │
    ┌─────────┴──────────┐
    │                    │
  캐시 없음            캐시 있음
    │                    │
    ▼                    ▼
  needsDownload      loadModelFromCache()
                         │
                    SHA-256 + 크기 검증
                         │
                  ┌──────┴──────┐
                  │             │
               검증 통과    검증 실패
                  │             │
                ready      needsDownload
                              (캐시 삭제)

첫 녹음 시 needsDownload이면:
  → _showModelDownloadDialog()
  → 사용자 동의 → downloadAndLoad()
  → 진행률 다이얼로그 (LinearProgressIndicator)
  → SHA-256 검증 → ready
```

---

## 12. CI/CD 파이프라인

### build-apk.yml (Debug 빌드)

```
트리거: push to main/master, PR to main/master, workflow_dispatch
환경: ubuntu-latest, Java 17 Temurin, Flutter stable
타임아웃: 25분

단계:
1. Checkout
2. Java 17 설정
3. Flutter stable 설정 (캐시 활성화)
4. 플러그인 compileSdk 패치 (sed로 36으로 일괄 변경)
5. flutter pub get
6. flutter analyze --no-fatal-infos (non-blocking)
7. flutter build apk --debug → build_output.txt
8. 성공: Artifacts에 debug APK 업로드 (14일 보관)
9. 성공: Slack 알림 (jq + curl)
   - 브랜치, 커밋 메시지, Artifacts 링크
10. 실패: error_tail.txt 생성 + Artifacts 업로드 (7일)
11. 실패: Slack 알림 (에러 요약 20줄 포함)
```

### release.yml (Release 빌드)

```
트리거: git tag v* (예: v1.0.0, v1.2.3)
환경: ubuntu-latest, Java 17 Temurin, Flutter stable
타임아웃: 30분

단계:
1. Checkout
2. 태그 추출 (GITHUB_REF에서 v* 파싱)
3. Java 17 설정
4. Flutter stable 설정
5. Android SDK 라이선스 자동 동의
6. flutter pub get
7. flutter clean && flutter pub get
8. flutter build apk --release --split-per-abi
   → app-arm64-v8a-release.apk (64-bit ARM 전용)
9. GitHub Release 생성
   - 태그: v*
   - 파일: app-arm64-v8a-release.apk 업로드
10. 성공: Slack 알림
    - APK 직접 다운로드 URL:
      https://github.com/{repo}/releases/download/{tag}/app-arm64-v8a-release.apk
11. 실패: Slack 알림 (에러 요약 + Actions 링크)

릴리즈 방법:
  git tag v1.x.x && git push origin v1.x.x
```

### Slack 알림 포맷

```
성공 (Debug):
  ✅ Meeting Assistant 빌드 성공 (#42)
  브랜치: main | 커밋: feat: ... | APK 다운로드: Artifacts 링크

실패 (Debug):
  ❌ Meeting Assistant 빌드 실패 (#42)
  브랜치: main | 커밋: ... | 에러 요약: ... | 전체 로그: Actions 링크

성공 (Release):
  🚀 Meeting Assistant v1.2.0 릴리즈 완료!
  버전: v1.2.0 | APK 다운로드: app-arm64-v8a-release.apk 직접 다운로드

실패 (Release):
  ❌ Meeting Assistant 릴리즈 빌드 실패 (v1.2.0)
  태그: v1.2.0 | 에러 요약: ... | 전체 로그: Actions 링크
```

---

## 13. Android 빌드 설정

```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.meeting_assistant"
        minSdk = 24      // Android 7.0 이상 지원
        targetSdk = 34
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs {
        release {
            // key.properties 존재 시 릴리즈 서명
            // 없으면 debug 서명으로 fallback (CI 환경)
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false    // Proguard/R8 비활성화
            isShrinkResources = false
        }
    }
}
```

**지원 기기**
- 최소: Android 7.0 (API 24)
- 권장: Android 10 (API 29) 이상, 4GB RAM 이상 (Gemma 1B 실행 권장)
- Release APK: arm64-v8a (64-bit ARM, 현행 Android 폰 대부분 해당)

---

## 14. 설정 항목 전체 목록

| 설정 항목 | 키 | 타입 | 기본값 | 용도 |
|-----------|-----|------|--------|------|
| OpenAI API 키 | `openai_api_key` | String? | null | Whisper STT 인증 |
| Notion API 토큰 | `notion_token` | String? | null | Notion 저장 인증 |
| Notion 페이지 URL | `notion_page_url` | String? | null | 저장 대상 페이지 |
| 자동 저장 여부 | `auto_save_to_notion` | bool | false | 회의록 완성 시 자동 업로드 |
| 회의록 작성 지침 | `minutes_instructions` | String? | null | Gemma 프롬프트 추가 지침 |

### OpenAI API 키 발급 방법
1. [platform.openai.com](https://platform.openai.com) 접속
2. API Keys → Create new secret key
3. 앱 설정 화면 → OPENAI STT → OpenAI API 키 입력 후 저장

### Notion 연동 설정 방법
1. Notion에서 새 페이지 생성
2. 연결 → Integration 추가 → Internal Integration 생성
3. 페이지 공유 → 초대 → 생성한 Integration 선택
4. Integration 토큰을 앱 설정 → API 토큰에 입력
5. Notion 페이지 URL을 앱 설정 → 노션 페이지 URL에 입력

---

*이 문서는 코드베이스 상태를 기반으로 자동 생성되었습니다.*
