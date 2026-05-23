#!/usr/bin/env bash
# 로컬 검증 후 GitHub 배포
# 사용법:
#   ./scripts/deploy.sh          — 일반 push (디버그 빌드 트리거)
#   ./scripts/deploy.sh v1.2.0   — 릴리즈 태그 push (릴리즈 APK 빌드 트리거)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."

TAG="${1:-}"

cd "$REPO_DIR"

echo "=== [1/3] 로컬 검증 ==="

# YAML 문법 검사 (워크플로우 파일)
if command -v python3 &>/dev/null; then
  python3 -c "
import yaml, glob, sys
files = glob.glob('.github/workflows/*.yml')
ok = True
for f in files:
    try:
        yaml.safe_load(open(f))
        print('  OK:', f)
    except Exception as e:
        print('  FAIL:', f, '-', e)
        ok = False
sys.exit(0 if ok else 1)
" && echo "  워크플로우 YAML 유효"
fi

# Git 상태 확인
UNCOMMITTED=$(git status --porcelain | wc -l)
if [ "$UNCOMMITTED" -gt 0 ]; then
  echo ""
  echo "  미커밋 변경사항이 있습니다:"
  git status --short
  echo ""
  read -p "  계속 진행하시겠습니까? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "  배포 취소."
    exit 0
  fi
fi

echo ""
echo "=== [2/3] Slack 알림 (배포 시작) ==="

SCRIPT_DIR2="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR2/../.env" ] && source "$SCRIPT_DIR2/../.env"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git log -1 --pretty=%s)

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  PAYLOAD=$(python3 -c "
import json
payload = {
    'text': ':rocket: *Meeting Assistant 배포 시작*',
    'attachments': [{
        'color': '#4a90e2',
        'fields': [
            {'title': '브랜치', 'value': '$BRANCH', 'short': True},
            {'title': '커밋', 'value': '$COMMIT', 'short': False}
        ]
    }]
}
print(json.dumps(payload, ensure_ascii=False))
")
  curl -s -o /dev/null -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-type: application/json' -d "$PAYLOAD"
  echo "  Slack 배포 시작 알림 전송"
else
  echo "  SLACK_WEBHOOK_URL 없음 — Slack 알림 건너뜀"
fi

echo ""
echo "=== [3/3] GitHub Push ==="

if [ -n "$TAG" ]; then
  echo "  릴리즈 태그: $TAG"
  git tag "$TAG"
  git push origin main
  git push origin "$TAG"
  echo "  태그 push 완료 → GitHub Actions가 릴리즈 APK 빌드 시작"
else
  git push origin main
  echo "  Push 완료 → GitHub Actions가 디버그 APK 빌드 시작"
fi

echo ""
echo "빌드 상태 확인: https://github.com/onjimin-arch/meeting-assistant/actions"
echo "CI 모니터링:    ./scripts/monitor-ci.sh"
