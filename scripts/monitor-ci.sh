#!/usr/bin/env bash
# CI 상태 확인 + 실패 시 Slack 알림
# 사용법: ./scripts/monitor-ci.sh
# 필요: SLACK_WEBHOOK_URL 환경변수 (또는 .env 파일)

set -euo pipefail

REPO="onjimin-arch/meeting-assistant"
API_BASE="https://api.github.com/repos/$REPO"

# .env 로드 (있으면)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  echo "[ERROR] SLACK_WEBHOOK_URL 환경변수가 없습니다."
  echo "  export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/..."
  exit 1
fi

echo "[CI Monitor] 최신 빌드 상태 확인 중..."
RUN=$(curl -s "$API_BASE/actions/runs?per_page=1")

STATUS=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['status'])")
CONCLUSION=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r.get('conclusion') or '')")
RUN_NUM=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['run_number'])")
RUN_ID=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['id'])")
BRANCH=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['head_branch'])")
RUN_URL=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['html_url'])")
CREATED=$(echo "$RUN" | python3 -c "import json,sys; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['created_at'])")

echo "  Run #$RUN_NUM | $STATUS / $CONCLUSION | 브랜치: $BRANCH"

if [ "$STATUS" != "completed" ]; then
  echo "[CI Monitor] 빌드 진행 중 — 대기 후 다시 실행하세요."
  exit 0
fi

if [ "$CONCLUSION" = "success" ]; then
  echo "[CI Monitor] 빌드 성공 — 조치 불필요."
  exit 0
fi

# 실패한 경우: 실패 step 이름 추출
FAILED_STEPS=$(curl -s "$API_BASE/actions/runs/$RUN_ID/jobs" | python3 -c "
import json, sys
data = json.load(sys.stdin)
failed = []
for job in data['jobs']:
    for step in job['steps']:
        if step.get('conclusion') == 'failure':
            failed.append(step['name'])
print(', '.join(failed) if failed else '알 수 없음')
")

echo "[CI Monitor] 빌드 실패 감지! 실패 step: $FAILED_STEPS"
echo "[CI Monitor] Slack 알림 전송 중..."

PAYLOAD=$(python3 -c "
import json
payload = {
    'text': ':red_circle: *Meeting Assistant CI 실패 — 자동 수정 필요*',
    'attachments': [{
        'color': '#e01e5a',
        'fields': [
            {'title': '빌드 번호', 'value': '#$RUN_NUM', 'short': True},
            {'title': '브랜치', 'value': '$BRANCH', 'short': True},
            {'title': '실패한 단계', 'value': '$FAILED_STEPS', 'short': False},
            {'title': '빌드 로그', 'value': '<$RUN_URL|GitHub Actions에서 보기>', 'short': False}
        ]
    }]
}
print(json.dumps(payload, ensure_ascii=False))
")

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-type: application/json' -d "$PAYLOAD")

if [ "$HTTP_CODE" = "200" ]; then
  echo "[CI Monitor] Slack 알림 전송 완료."
else
  echo "[CI Monitor] Slack 전송 실패 (HTTP $HTTP_CODE)"
fi

# 실패 정보를 stdout에 출력해 AI가 읽고 수정할 수 있도록
echo ""
echo "=== 자동 수정 컨텍스트 ==="
echo "FAILED_STEPS: $FAILED_STEPS"
echo "RUN_URL: $RUN_URL"
echo "RUN_ID: $RUN_ID"
echo "다음 단계: 위 step 이름을 기반으로 소스 코드 수정 후 scripts/deploy.sh 실행"
