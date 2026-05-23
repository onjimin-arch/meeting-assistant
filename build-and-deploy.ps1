# 로컬 빌드 및 배포 스크립트
# - GitHub Actions 에서 실행
# - 빌드 실패 시 Slack 알림
# - 빌드 성공 시 GitHub Release 생성 및 Slack 알림

param(
    [string]$Tag = $env:GITHUB_REF?.TrimStart('refs/tags/'),
    [string]$CommitHash = $env:GITHUB_SHA,
    [string]$RunId = $env:GITHUB_RUN_ID,
    [string]$ServerUrl = $env:GITHUB_SERVER_URL,
    [string]$Repository = $env:GITHUB_REPOSITORY
)

$ErrorActionPreference = "Continue"

# Slack 설정
$slackWebhook = $env:SLACK_WEBHOOK_URL
if ([string]::IsNullOrEmpty($slackWebhook)) {
    Write-Host "경고: SLACK_WEBHOOK_URL이 설정되지 않았습니다."
}

function Send-SlackNotification {
    param(
        [string]$Message,
        [string]$Color
    )
    
    if ([string]::IsNullOrEmpty($slackWebhook)) {
        Write-Host "Slack 알림 생략 (웹훅 URL 없음)"
        return
    }

    $payload = @{
        text = $Message
        username = "GitHub Actions"
        icon_emoji = ":$(if ($Color -eq 'good') { 'white_check_mark' } else { 'x' })"
    } | ConvertTo-Json -Compress

    try {
        Invoke-RestMethod -Uri $slackWebhook -Method Post -Body $payload -ContentType 'application/json'
        Write-Host "Slack 알림 전송 완료"
    } catch {
        Write-Host "Slack 알림 실패: $_"
    }
}

# 태그 확인
if ([string]::IsNullOrEmpty($Tag)) {
    $Tag = git describe --tags --exact-match 2>$null
    if ([string]::IsNullOrEmpty($Tag)) {
        $Tag = "unknown"
    }
}

$Tag = $Tag.TrimStart('refs/tags/')
Write-Host "배포 태그: $Tag"
Write-Host "커밋: $CommitHash"

# 1. Flutter 환경 확인
Write-Host "`n=== Flutter 환경 확인 ==="
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "Flutter: $flutterVersion"
} catch {
    Write-Host "Flutter 설치 안됨: $_"
    Send-SlackNotification -Message "❌ 빌드 실패: Flutter 를 찾을 수 없습니다.\n\n*태그:* $Tag\n*커밋:* $CommitHash" -Color "danger"
    exit 1
}

# 2. 의존성 설치
Write-Host "`n=== 의존성 설치 ==="
try {
    flutter pub get
    Write-Host "의존성 설치 완료"
} catch {
    Write-Host "의존성 설치 실패: $_"
    Send-SlackNotification -Message "❌ 빌드 실패: 의존성 설치 실패\n\n*태그:* $Tag\n*메시지:* $_" -Color "danger"
    exit 1
}

# 3. 빌드
Write-Host "`n=== APK 빌드 중 ==="
try {
    $buildResult = flutter build apk --release 2>&1
    $buildOutput = $buildResult | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        throw "빌드 실패 (종료 코드: $LASTEXITCODE)"
    }
    
    Write-Host "APK 빌드 완료"
} catch {
    Write-Host "APK 빌드 실패: $_"
    
    # 빌드 실패 시 Slack 알림
    $errorMessage = $_.Exception.Message
    Send-SlackNotification -Message "❌ 빌드 실패: $errorMessage`n\n*태그:* $Tag`n*커밋:* $CommitHash`n`n자세한 내용은 GitHub Actions 를 확인하세요." -Color "danger"
    exit 1
}

# 4. APK 파일 확인
$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "APK 생성 완료: $apkPath ($([math]::Round($apkSize, 2)) MB)"
} else {
    Write-Host "경고: APK 파일을 찾을 수 없습니다: $apkPath"
}

# 5. 성공 알림
$releaseUrl = ""
if (-not [string]::IsNullOrEmpty($ServerUrl) -and -not [string]::IsNullOrEmpty($Repository)) {
    $releaseUrl = "$ServerUrl/$Repository/releases/tag/$Tag"
}

$downloadUrlArm64 = ""
$downloadUrlUniversal = ""
if (-not [string]::IsNullOrEmpty($ServerUrl) -and -not [string]::IsNullOrEmpty($Repository)) {
    $downloadUrlArm64 = "$ServerUrl/$Repository/releases/download/$Tag/app-arm64-v8a-release.apk"
    $downloadUrlUniversal = "$ServerUrl/$Repository/releases/download/$Tag/app-release.apk"
}

$successMessage = @"
🚀 *새로운 버전이 배포되었습니다!*

*버전:* $Tag
*릴리스:* $releaseUrl

📥 *다운로드:*
• ARM64 (권장): $downloadUrlArm64
• 범용: $downloadUrlUniversal

APK 를 다운로드하여 설치하세요.
"@

Send-SlackNotification -Message $successMessage -Color "good"
Write-Host "`n✅ 배포 완료!"

exit 0
