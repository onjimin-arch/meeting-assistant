# Slack 에 직접 알림 보내기
# 사용법: .\send-slack.ps1 -Message "테스트" -Success $true

param(
    [string]$Message = "",
    [bool]$Success = $true,
    [string]$Tag = "",
    [string]$WebhookUrl = ""
)

# 환경 변수에서 웹훅 URL 가져오기
if ([string]::IsNullOrEmpty($WebhookUrl)) {
    $WebhookUrl = $env:SLACK_WEBHOOK_URL
}

if ([string]::IsNullOrEmpty($WebhookUrl)) {
    Write-Host "오류: SLACK_WEBHOOK_URL 환경 변수가 설정되지 않았습니다."
    Write-Host "다음 명령으로 설정하세요:"
    Write-Host '  [Environment]::SetEnvironmentVariable("SLACK_WEBHOOK_URL", "https://hooks.slack.com/...", "User")'
    exit 1
}

if ([string]::IsNullOrEmpty($Message)) {
    $Message = "테스트 메시지입니다."
}

if ([string]::IsNullOrEmpty($Tag)) {
    $Tag = git describe --tags --exact-match 2>$null
    if ([string]::IsNullOrEmpty($Tag)) {
        $Tag = "unknown"
    }
}

$payload = @{
    text = if ($Success) {
        "🚀 *배포 성공!*\n\n$Message`n`n*버전:* $Tag"
    } else {
        "❌ *배포 실패!*\n\n$Message`n`n*버전:* $Tag"
    }
    username = "GitHub Actions"
    icon_emoji = if ($Success) { ":white_check_mark:" } else { ":x:" }
} | ConvertTo-Json -Compress

try {
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
    Write-Host "✅ Slack 알림 전송 완료"
} catch {
    Write-Host "❌ Slack 알림 실패: $_"
    Write-Host "응답: $($_.Exception.Message)"
}
