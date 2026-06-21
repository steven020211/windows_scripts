# 早安新聞排程安裝腳本
# 使用方式：以系統管理員執行此腳本

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$taskName = "DailyNewsDigest"
$computerName = $env:COMPUTERNAME
$userName = "$computerName\$env:USERNAME"

if (-not (Test-Path "$scriptPath\daily-news.ps1")) {
    Write-Host "錯誤：找不到 daily-news.ps1，請確認檔案放在同一個資料夾。" -ForegroundColor Red
    exit 1
}

Write-Host "=== 早安新聞排程安裝 ===" -ForegroundColor Cyan
Write-Host ""

$webhook = Read-Host "請輸入 Discord Webhook URL"
if ([string]::IsNullOrWhiteSpace($webhook)) {
    Write-Host "錯誤：Webhook URL 不能為空" -ForegroundColor Red
    exit 1
}

$apiKey = Read-Host "請輸入 OpenRouter API Key"
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "錯誤：API Key 不能為空" -ForegroundColor Red
    exit 1
}

# Escape single quotes for the PowerShell command
$webhookEscaped = $webhook -replace "'", "''"
$apiKeyEscaped = $apiKey -replace "'", "''"

$psCommand = "`$env:DISCORD_WEBHOOK_URL='$webhookEscaped'; `$env:OPENROUTER_API_KEY='$apiKeyEscaped'; & '$scriptPath\daily-news.ps1'; if (`$?) { shutdown /s /t 60 }"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command '$psCommand'"
$trigger = New-ScheduledTaskTrigger -Daily -At 07:00AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $userName -LogonType Interactive -RunLevel Limited

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
    Write-Host ""
    Write-Host "✅ 安裝成功！" -ForegroundColor Green
    Write-Host "   排程名稱：$taskName"
    Write-Host "   執行時間：每天 07:00"
    Write-Host "   成功發送後：60 秒自動關機（可用 shutdown /a 取消）"
    Write-Host ""
    Write-Host "若要立即測試，請執行："
    Write-Host "   powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"`$env:DISCORD_WEBHOOK_URL='$webhookEscaped'; `$env:OPENROUTER_API_KEY='$apiKeyEscaped'; & '$scriptPath\daily-news.ps1'`""
} catch {
    Write-Host "❌ 安裝失敗：$_" -ForegroundColor Red
}
