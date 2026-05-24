# Meeting Assistant - 개발 완료 및 배포 가이드

최종 업데이트: 2026-05-24  
상태: ✅ 개발 완료 → 🚀 배포 준비 완료

---

## 📋 완료된 작업

### 1. 문서화 완료 ✅
- [x] `ARCHITECTURE.md` 삭제 (문서 일원화)
- [x] `CLAUDE.md` 업데이트 (OpenAI/Gemma 하이브리드 아키텍처 반영)
- [x] `README.md` 업데이트 (사용자 가이드 최신화)
- [x] Git 커밋 및 GitHub Push 완료

### 2. 아키텍처 명확화 ✅
- **STT**: OpenAI Whisper API (클라우드)
- **LLM**: 
  - OpenAI GPT-4o-mini (클라우드) - `useCloudLlm = true`
  - Gemma 3 1B Instruct (온디바이스) - `useCloudLlm = false`
- **오디오 녹음**: AAC-LC, 128kbps, 44.1kHz
- **Notion 연동**: REST API v1 (마크다운 블록 변환)

### 3. 구현된 핵심 서비스 ✅
- [x] `AudioRecorderService` - AAC 오디오 녹음
- [x] `WhisperApiService` - OpenAI Whisper API (음성 → 텍스트)
- [x] `OpenAiLlmService` - OpenAI GPT (회의록/채팅)
- [x] `GemmaInferenceService` - Gemma 온디바이스 (회의록/채팅)
- [x] `NotionSyncService` - Notion API 연동
- [x] `AppSettingsService` - 설정 영속화
- [x] `MeetingRepository` - 회의 목록 관리

### 4. 구현된 UI 화면 ✅
- [x] `HomeScreen` - 회의 목록 + 녹음 버튼
- [x] `RecordingScreen` - 웨이브폼 + 타이머
- [x] `ProcessingScreen` - 단계별 진행 표시
- [x] `MinutesScreen` - 회의록/스크립트 탭
- [x] `ChatScreen` - 추가 작업 채팅
- [x] `SettingsScreen` - OpenAI/Notion 설정, LLM 선택

### 5. CI/CD 설정 ✅
- [x] `.github/workflows/build-apk.yml` - 디버그 빌드 (PR/push)
- [x] `.github/workflows/release.yml` - 릴리즈 빌드 (v* 태그)
- [x] `scripts/deploy.sh` - 로컬 배포 스크립트
- [x] `scripts/monitor-ci.sh` - CI 모니터링
- [x] Slack 연동 (빌드 성공/실패 알림)

---

## 🚀 배포 방법

### 1. 선수 조건 설정

#### GitHub Secrets 설정
GitHub 저장소 → Settings → Secrets and variables → Actions:

```
SLACK_WEBHOOK_URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

#### Slack Webhook URL 발급
1. https://api.slack.com/apps → Create New App
2. Incoming Webhooks → Activate
3. Add to Workspace → 채널 선택 → URL 복사

#### 로컬 .env 설정 (선택)
```bash
cp .env.example .env
# .env 편집: SLACK_WEBHOOK_URL 입력
```

### 2. 디버그 빌드 (테스트)

```bash
# 1. 변경사항 커밋
git add -A
git commit -m "feat: 기능 설명"

# 2. GitHub 로 푸시 (자동으로 CI 시작)
git push origin main

# 또는 deploy.sh 사용
./scripts/deploy.sh
```

**결과**:
- GitHub Actions 에서 빌드 시작
- 성공 시: APK 다운로드 링크를 Slack 으로 알림
- 실패 시: 에러 요약을 Slack 으로 알림

### 3. 릴리즈 빌드 (프로덕션)

```bash
# 1. 버전 태그로 푸시
git tag v1.0.0
git push origin main
git push origin v1.0.0

# 또는 deploy.sh 사용
./scripts/deploy.sh v1.0.0
```

**결과**:
- GitHub Actions 가 릴리즈 APK 빌드
- GitHub Releases 에 APK 자동 업로드
- 다운로드 전용 링크를 Slack 으로 알림
- URL: `https://github.com/onjimin-arch/meeting-assistant/releases/tag/v1.0.0`

### 4. 빌드 상태 모니터링

```bash
# CI 상태 확인
./scripts/monitor-ci.sh

# GitHub Actions 웹에서 확인
https://github.com/onjimin-arch/meeting-assistant/actions
```

---

## 📦 설치 파일

### APK 다운로드 경로
- **디버그 빌드**: GitHub Actions → Artifacts (14 일 보관)
- **릴리즈 빌드**: GitHub Releases (영구)

### 설치 방법
1. APK 다운로드
2. 안드로이드 폰으로 파일 전송 (구글드라이브, 카톡 등)
3. 설정 → 보안 → "알 수 없는 출처 앱" 허용
4. APK 설치

### 최소 요구사항
- Android 7.0 (API 24) 이상
- 저장공간 1GB 이상 (Gemma 모델 530MB)
- RAM 4GB 이상 권장

---

## 🔧 주요 설정

### 1. OpenAI API 키 설정
1. https://platform.openai.com/api-keys
2. API 키 복사
3. 앱 실행 → 설정 → OpenAI API 키 입력

### 2. LLM 엔진 선택
- **OpenAI GPT**: 빠른 처리, 정확한 결과, API 키 필요
- **Gemma 온디바이스**: 오프라인 동작, 첫 사용 시 다운로드

### 3. Notion 연동
1. https://www.notion.so/my-integrations
2. Integration 생성 → 토큰 복사
3. 앱 설정 → API 토큰 + 페이지 URL 입력

---

## 📊 Git 커밋 이력

```
679a31b docs: 아키텍처 문서 통합 (ARCHITECTURE.md 삭제) 및 OpenAI/Gemma 하이브리드 아키텍처 반영
7663ee5 fix: Meeting 클래스 복구 (useCloudLlm 추가 시 실수로 삭제됨)
ba0eb0f fix: pub-cache 패치 제거 (sed가 compileSdk = 36 형식 깨뜨리는 버그)
5b46789 fix: compileSdk 34→35 업그레이드 + 릴리즈 빌드 단순화
e3c8b1d fix: 릴리즈 빌드 실패 원인 수정 (compileSdk 패치 누락 + pipefail)
```

---

## 🎯 다음 단계 (선택)

### 6 단계: Notion 연동 구현
- [ ] `notion-integration` 서브에이전트 호출
- [ ] 마크다운 → Notion 블록 변환기 구현
- [ ] 에러 처리 및 재시도 로직

### 7 단계: 데이터베이스 통합
- [ ] SQLite (drift) 스키마 정의
- [ ] 회의 CRUD 연산
- [ ] 대용량 데이터 최적화

### 8 단계: 테스트 및 최적화
- [ ] E2E 플로우 테스트
- [ ] 성능 프로파일링
- [ ] 메모리 최적화

---

## 📞 문제 해결

### 빌드 실패
1. GitHub Actions 로그 확인
2. `flutter analyze` 로 로컬 분석
3. `flutter clean && flutter pub get`

### Slack 알림 미수신
1. `.env` 파일에 `SLACK_WEBHOOK_URL` 확인
2. GitHub Secrets 에 등록 확인
3. 웹훅 URL 유효성 확인

### APK 설치 안 됨
1. 안드로이드 버전 확인 (7.0 이상)
2. 저장공간 확인 (1GB 이상)
3. "알 수 없는 출처 앱" 허용 확인

---

**마지막 업데이트**: 2026 년 5 월 24 일  
**버전**: 1.0.0  
**상태**: 🟢 개발 완료 → 🚀 배포 준비 완료
