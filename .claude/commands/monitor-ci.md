# CI 모니터링 & 자동 수정

GitHub Actions 최신 빌드 상태를 확인하고, 실패 시 에러를 분석해 자동 수정 후 재배포합니다.

## 실행 방법
이 명령어를 실행하면 Claude Code가 다음을 자동으로 수행합니다:

1. GitHub API로 `onjimin-arch/meeting-assistant` 최신 워크플로우 실행 결과 조회
2. 상태 확인:
   - `success` → Slack에 이미 알림 전송됨. 별도 조치 불필요
   - `failure` → 아래 자동 수정 플로우 진행
   - `in_progress` → 완료까지 대기 (30초 간격 폴링)
3. **실패 시 자동 수정 플로우**:
   a. GitHub Actions 빌드 로그 artifact 다운로드
   b. 에러 분석 (Dart/Flutter/Gradle 에러 패턴 파악)
   c. 해당 소스 파일 수정
   d. `git commit -m "fix: CI 빌드 오류 자동 수정 (#<run_number>)"`
   e. `git push origin main`
   f. 새 빌드가 다시 트리거됨 → Slack 알림 전송

## 주요 에러 패턴 & 수정 전략

| 에러 | 원인 | 수정 방법 |
|------|------|-----------|
| `Could not resolve` | 패키지 버전 충돌 | pubspec.yaml 버전 다운그레이드 |
| `Undefined name` | import 누락 또는 타입 오류 | 해당 파일 import/타입 수정 |
| `compileSdk` 불일치 | Gradle 버전 문제 | 워크플로우 patch 스텝 확인 |
| `minSdkVersion` | API 레벨 요구사항 | build.gradle.kts minSdk 조정 |
| `flutter_gemma` 오류 | MediaPipe 네이티브 설정 | gradle 의존성 확인 |

## GitHub API 엔드포인트
- 워크플로우 목록: `https://api.github.com/repos/onjimin-arch/meeting-assistant/actions/runs?per_page=1`
- 로그 artifact: `https://api.github.com/repos/onjimin-arch/meeting-assistant/actions/runs/{run_id}/artifacts`
