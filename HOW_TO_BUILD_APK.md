# APK 한 파일로 폰에 설치하기 — 따라하기 가이드

USB 연결 없이 **APK 파일 1개**만 폰으로 옮겨서 설치하는 전체 흐름입니다.
PC에는 Flutter/Android Studio를 깔지 않고, **GitHub의 무료 클라우드(GitHub Actions)** 에서 빌드합니다.

---

## 큰 그림 (3단계)

```
[1] GitHub에 코드 푸시
       ↓
[2] GitHub Actions가 클라우드에서 APK 빌드 → "Artifacts"로 제공
       ↓
[3] APK 다운로드 → 구글 드라이브/카톡 등으로 폰에 전송 → 설치
```

소요 시간: 처음 1회 세팅 30분, 이후 코드 수정 시 빌드 6~8분.

---

## 사전 준비

- [ ] **GitHub 계정** (없으면 [github.com/signup](https://github.com/signup))
- [ ] **GitHub Desktop** 설치 (CLI 없이 GUI로 푸시) → [desktop.github.com](https://desktop.github.com)
- [ ] 안드로이드 폰

> Mac/iPhone 사용자는 추가로 Apple 개발자 계정($99/년)이 필요해 별도 안내합니다.
> 이 문서는 **안드로이드 APK 배포** 기준입니다.

---

## STEP 1 — GitHub에 코드 푸시

### 1-1. 새 저장소 만들기
1. [github.com/new](https://github.com/new) 접속
2. **Repository name**: `meeting-assistant` (원하는 이름)
3. **Private** 권장 (코드 비공개)
4. README/.gitignore/license 추가 옵션은 **모두 체크 해제** (이미 프로젝트에 있음)
5. **Create repository** 클릭

### 1-2. GitHub Desktop으로 이 프로젝트 폴더 푸시
1. GitHub Desktop 실행 → 로그인
2. **File → Add Local Repository** →
   `C:\Users\jmlee\OneDrive - 바로고\문서\클로드 코드 에이전트\회의록 앱` 선택
3. "create a repository" 링크가 보이면 클릭 → **Create Repository**
4. 좌하단 **Summary** 칸에 `initial commit` 입력 → **Commit to main**
5. 상단 **Publish repository** 클릭 → 방금 만든 저장소 이름 확인 → **Publish**

> 이미 git 저장소면 1번 직후 바로 보임. 그러면 `Publish repository`로 바로 진행.

---

## STEP 2 — GitHub Actions로 APK 빌드

### 2-1. 자동 빌드 확인
푸시한 직후 GitHub 저장소 페이지에서 **Actions** 탭 클릭.
`Build Android APK` 워크플로우가 자동 실행 중일 것임 (노란색 ●).
완료까지 약 **6~8분** 대기. ✅ 녹색 체크로 바뀌면 성공.

### 2-2. 수동 재실행이 필요할 때
- 코드 수정 없이 다시 빌드하려면: **Actions → Build Android APK →
  Run workflow → Run workflow** 버튼 클릭.

### 2-3. 빌드 실패 시
`Actions` 탭에서 실패한 실행 클릭 → 어느 step에서 빨간 ✗ 가 났는지 확인.
가장 흔한 원인:
- **`flutter pub get` 실패** → `pubspec.yaml`의 패키지 버전 호환성 문제
- **Gradle/AndroidManifest 오류** → 워크플로우의 `Generate Android platform folder` 단계 로그 확인

로그를 그대로 복사해서 Claude에 붙여주면 진단해 드립니다.

---

## STEP 3 — APK 다운로드 & 폰에 설치

### 3-1. APK 다운로드 (PC에서)
1. **Actions** 탭 → 성공한(✓) 빌드 클릭
2. 페이지 하단 **Artifacts** 섹션 → `meeting-assistant-apk` 클릭
3. zip 파일 다운로드 → 압축 풀면 아래 3개 + 1개 = **4개 파일**:
   ```
   app-arm64-v8a-release.apk    ← 최신 폰 99%는 이거 (작고 빠름) ★
   app-armeabi-v7a-release.apk  ← 구형 32bit 폰
   app-x86_64-release.apk       ← 에뮬레이터용
   app-release.apk              ← 모든 ABI 포함 (가장 크지만 어디든 동작)
   ```
4. **확신 없으면 `app-release.apk` 1개만** 쓰면 됨 (단일 파일, 모든 기기 호환)

### 3-2. APK를 폰으로 옮기기 (USB 없이)
한 가지만 골라서 사용:

| 방법 | 어떻게 |
|---|---|
| **구글 드라이브** ⭐ | PC 드라이브에 APK 업로드 → 폰 드라이브 앱에서 다운로드 |
| **카카오톡 "나에게 보내기"** | PC카톡에서 파일 전송 → 폰카톡에서 저장 |
| **이메일** | 자기 자신에게 APK 첨부 전송 → 폰에서 다운로드 |
| **Send Anywhere / AirDroid** | 코드 한 줄로 P2P 전송 |

### 3-3. 폰에서 설치 (안드로이드)
1. 폰의 파일 관리자(또는 드라이브 앱)에서 받은 APK 탭
2. **"출처를 알 수 없는 앱 설치 허용"** 토글 ON
   - Android 12+: "이 앱은 이 출처에서 앱을 설치할 수 있도록 허용되지 않았습니다" 팝업 → **설정** → 토글 ON → 뒤로가기
3. **설치** 버튼 → 완료
4. 홈 화면에 "Meeting Assistant" 아이콘 생김

> "Play Protect가 차단했습니다" 경고가 뜨면 **상세보기 → 어쨌든 설치** 누르면 됩니다.
> (Google Play를 거치지 않은 모든 APK에 뜨는 정상 경고)

---

## 현재 빌드의 동작 범위

- ✅ 6개 화면 전부 동작 (홈/녹음/처리/회의록/채팅/설정)
- ✅ 화면 전환, 설정 저장 (Notion 토큰 등), 빠른 옵션 선택
- ✅ **STT 실제 동작** — 폰 내장 Google/Apple 음성인식 엔진
- ✅ **회의록 자동 생성 실제 동작** — Gemma 3 1B (온디바이스)
- ✅ **추가 작업 채팅 실제 동작** — Gemma가 transcript+회의록 보고 응답
- ✅ **로컬 저장** — 녹음한 회의가 폰 내부에 영구 보관
- ⚠️ Notion 저장은 아직 mock (token 입력해도 진짜 페이지 안 만들어짐)

### 첫 실행 시 — 모델 다운로드 필요

녹음 버튼을 처음 누르면 **AI 모델(약 530MB)** 다운로드 다이얼로그가 뜹니다.
- Wi-Fi 권장 (LTE로 받으면 데이터 많이 씀)
- 한 번 받으면 다신 안 받음, 인터넷 없이도 동작
- 다운로드 5~15분 소요 (네트워크 속도에 따라)

### 회의록 생성 속도

폰 CPU로 LLM 추론하므로 빠르지 않습니다.
- 짧은 회의(5분): 회의록 생성 약 **10~20초**
- 긴 회의(30분+): 약 **30~60초**
- 채팅 응답: **5~15초**

체감 느려도 정상입니다. 더 빠르게 하려면 큰 모델(Gemma 2B, 1.5GB)로 바꾸지 말고, 회의 transcript를 짧게 만들어 보세요.

### STT 동작 조건

- 인터넷 연결 권장 (오프라인 한국어 STT 미지원 기종 多)
- 첫 실행 시 **마이크 권한** 허용 필요
- "음성 인식 서비스 없음" 에러 → Play 스토어 "Google" / "Speech Services by Google" 업데이트

---

## 자주 묻는 질문

**Q. APK 크기가 얼마나 되나요?**
A. APK 자체는 약 40~60MB. Gemma 3 1B 모델은 첫 녹음 시 약 530MB 별도 다운로드. STT는 폰 내장 엔진 사용으로 추가 다운로드 없음.

**Q. iOS도 같은 방식 가능한가요?**
A. 안 됩니다. iOS는 정식 배포(App Store) 또는 TestFlight 또는 사이드로딩(AltStore 등)이 필요하며, $99/년 Apple 개발자 계정이 별도 필요합니다.

**Q. GitHub Actions가 무료인가요?**
A. Private 저장소도 월 2,000분 무료. 1회 빌드 8분 기준 월 250회 빌드 가능.

**Q. 코드를 수정하면 어떻게 새 APK를 받나요?**
A. GitHub Desktop에서 변경사항 commit → push. Actions가 자동으로 새 APK 빌드. 끝나면 STEP 3 반복.

---

## 빠른 체크리스트

- [ ] GitHub 계정 + GitHub Desktop 설치
- [ ] 새 저장소 만들기 (Private)
- [ ] GitHub Desktop에서 이 폴더 publish
- [ ] Actions 탭에서 ✓ 녹색 확인 (6~8분)
- [ ] Artifacts에서 zip 다운로드
- [ ] `app-release.apk` 폰으로 전송
- [ ] 폰에서 "알 수 없는 출처 설치" 허용 → 설치
