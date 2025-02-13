Write-Host "產生每日凌晨一點執行檔案檢查..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -Command "c:\log\clean_PWR.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 1am
Register-ScheduledTask -TaskName "每日清理任務" -Action $action -Trigger $trigger -RunLevel Highest
Write-Host "如果有看到每日清理任務代表安裝成功"
Get-ScheduledTask -TaskName "每日清理任務"

