# 배포 자동화 스크립트 (재시도 + 자동 수정)
# 배포 실패 시 자동으로 수정 시도 후 재배포

param(
    [string]$Tag = "",
    [int]$MaxRetries = 3,
    [int]$RetryDelaySeconds = 30
)

$ErrorActionPreference = "Stop"

function Get-LatestCommitHash {
    return (git rev-parse HEAD).Trim()
}

function Get-RemoteCommitHash {
    try {
        $remoteRef = git ls-remote origin main | ForEach-Object { $_.Split()[0] }
        return $remoteRef
    } catch {
        return ""
    }
}

function Wait-ForWorkflowComplete {
    param(
        [string]$CommitHash,
        [int]$TimeoutMinutes = 10
    )
    
    $startTime = Get-Date
    $timeout = [TimeSpan]::FromMinutes($TimeoutMinutes)
    
    Write-Host "🔄 워크플로우 완료 대기 중... (타임아웃: $TimeoutMinutes 분)"
    
    while ((New-TimeSpan -Start $startTime -End (Get-Date)) -lt $timeout) {
        try {
            # GitHub CLI 로 워크플로우 상태 확인
            $runs = gh run list --limit 1 --json status,conclusion,databaseId 2>$null | ConvertFrom-Json
            
            if ($runs) {
                $status = $runs[0].status
                $conclusion = $runs[0].conclusion
                
                if ($status -eq "completed") {
                    return $conclusion
                }
            }
        } catch {
            Write-Host "경고: 워크플로우 상태 확인 실패: $_"
        }
        
        Start-Sleep -Seconds 10
    }
    
    return "timeout"
}

function Test-GitHubActionsStatus {
    param(
        [string]$CommitHash
    )
    
    try {
        $runs = gh run list --limit 5 --json status,conclusion,headSha 2>$null | ConvertFrom-Json
        
        foreach ($run in $runs) {
            if ($run.headSha -eq $CommitHash) {
                if ($run.status -eq "completed") {
                    return $run.conclusion -eq "success"
                }
            }
        }
        
        return $true # 아직 완료되지 않음
    } catch {
        Write-Host "경고: GitHub CLI 확인 실패: $_"
        return $false
    }
}

function Send-SlackNotification {
    param(
        [string]$Message,
        [string]$Status
    )
    
    $slackWebhook = $env:SLACK_WEBHOOK_URL
    if ([string]::IsNullOrEmpty($slackWebhook)) {
        Write-Host "경고: SLACK_WEBHOOK_URL 환경 변수가 설정되지 않았습니다."
        return
    }
    
    $payload = @{
        text = $Message
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $slackWebhook -Method Post -Body $payload -ContentType 'application/json'
        Write-Host "📢 Slack 알림 전송 완료"
    } catch {
        Write-Host "경고: Slack 알림 실패: $_"
    }
}

function Fix-CommonIssues {
    param(
        [string]$ErrorMessage
    )
    
    Write-Host "🔧 일반적인 문제 자동 수정 시도..."
    
    # 1. pubspec.yaml 무결성 확인
    if ($ErrorMessage -like "*pubspec*" -or $ErrorMessage -like "*dependency*") {
        Write-Host "  → pubspec.yaml 정합성 확인 중..."
        try {
            flutter pub get
            Write-Host "  ✓ pubspec.yaml 정상"
        } catch {
            Write-Host "  ✗ pubspec.yaml 오류 - 수동 확인 필요"
            return $false
        }
    }
    
    # 2. Flutter Doctor 확인
    if ($ErrorMessage -like "*Flutter*" -or $ErrorMessage -like "*SDK*") {
        Write-Host "  → Flutter 환경 확인 중..."
        $doctor = flutter doctor 2>&1
        if ($doctor -like "*issue*" -or $doctor -like "*error*") {
            Write-Host "  ✗ Flutter 환경 오류 - doctor 확인 필요"
            flutter doctor
            return $false
        }
        Write-Host "  ✓ Flutter 환경 정상"
    }
    
    # 3. 디스크 공간 확인
    $drive = Get-PSDrive (Get-Location).Path.Split('\')[0].TrimEnd(':')
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -lt 5) {
        Write-Host "  ✗ 디스크 공간 부족: ${freeSpaceGB}GB 남음"
        return $false
    }
    Write-Host "  ✓ 디스크 공간 충분: ${freeSpaceGB}GB"
    
    return $true
}

function Deploy-WithRetry {
    $commitHash = Get-LatestCommitHash
    Write-Host "현재 커밋: $commitHash"
    
    $attempt = 1
    $success = $false
    
    while ($attempt -le $MaxRetries -and -not $success) {
        Write-Host "`n🚀 배포 시도 $attempt/$MaxRetries"
        Write-Host "====================================="
        
        try {
            # 1. 로컬 변경사항 확인
            $status = git status --porcelain
            if ($status) {
                Write-Host "  → 로컬 변경사항 커밋 중..."
                git add .
                git commit -m "deploy: 자동 커밋 (시도 $attempt)"
            }
            
            # 2. 최신 코드 병합
            Write-Host "  → 원격 저장소와 동기화 중..."
            git pull --rebase origin main
            
            # 3. 태그 생성 (버전 자동 증가)
            if ([string]::IsNullOrEmpty($Tag)) {
                $existingTags = git tag --list "v*" | Sort-Object -Descending
                if ($existingTags) {
                    $latestTag = $existingTags[0]
                    $versionParts = $latestTag.TrimStart('v').Split('.')
                    if ($versionParts.Count -ge 3) {
                        $major = [int]$versionParts[0]
                        $minor = [int]$versionParts[1]
                        $patch = [int]$versionParts[2]
                        $patch++
                        $newTag = "v$major.$minor.$patch"
                    } else {
                        $newTag = "v1.0.0"
                    }
                } else {
                    $newTag = "v1.0.0"
                }
            } else {
                $newTag = $Tag
            }
            
            Write-Host "  → 릴리스 태그: $newTag"
            
            # 기존 태그 삭제 (있으면)
            git tag -d $newTag 2>$null
            git push origin :refs/tags/$newTag 2>$null
            
            # 새 태그 생성 및 푸시
            git tag $newTag
            Write-Host "  → 태그 푸시 중..."
            git push origin $newTag
            
            # 4. 워크플로우 완료 대기
            Write-Host "  → 빌드 상태 확인 중..."
            $result = Wait-ForWorkflowComplete -CommitHash $commitHash -TimeoutMinutes 15
            
            if ($result -eq "success") {
                Write-Host "`n✅ 배포 성공!"
                Send-SlackNotification -Message "✅ 배포 성공: $newTag" -Status "success"
                $success = $true
            } else {
                Write-Host "`n❌ 배포 실패 (상태: $result)"
                
                # 5. 실패 원인 분석 및 수정
                if ($attempt -lt $MaxRetries) {
                    Write-Host "`n🔍 실패 원인 분석 및 수정 시도..."
                    $fixSuccess = Fix-CommonIssues -ErrorMessage "distribution"
                    
                    if ($fixSuccess) {
                        Write-Host "  → 수정 완료, $RetryDelaySeconds 초 후 재시도..."
                        Start-Sleep -Seconds $RetryDelaySeconds
                    } else {
                        Write-Host "  → 자동 수정 불가, 수동 개입 필요"
                        Send-SlackNotification -Message "❌ 배포 실패 (수동 수정 필요): $newTag`n$commitHash" -Status "failure"
                        break
                    }
                }
            }
        } catch {
            Write-Host "`n❌ 배포 중 오류: $_"
            
            if ($attempt -lt $MaxRetries) {
                Write-Host "  → $RetryDelaySeconds 초 후 재시도..."
                Start-Sleep -Seconds $RetryDelaySeconds
            } else {
                Send-SlackNotification -Message "❌ 배포 실패 (최대 재시도 초과): $newTag`n오류: $_" -Status "failure"
            }
        }
        
        $attempt++
    }
    
    if (-not $success) {
        Write-Host "`n❌ 최대 재시도 횟수 초과 ($MaxRetries 회)"
        Send-SlackNotification -Message "❌ 배포 실패 (최대 재시도 $MaxRetries 회 모두 실패)" -Status "failure"
        return $false
    }
    
    return $true
}

# 메인 실행
Write-Host "====================================="
Write-Host "🚀 자동 배포 스크립트 (재시도 포함)"
Write-Host "====================================="
Write-Host "최대 재시도: $MaxRetries 회"
Write-Host "재시도 간격: $RetryDelaySeconds 초"
Write-Host ""

$deploySuccess = Deploy-WithRetry

if ($deploySuccess) {
    Write-Host "`n🎉 배포가 성공적으로 완료되었습니다!"
    exit 0
} else {
    Write-Host "`n💥 배포가 실패했습니다. 로그를 확인하세요."
    exit 1
}
