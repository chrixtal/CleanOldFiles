# 設定目錄路徑
$saveImgDirs = @("D:\save_img", "E:\save_img")
$stitchImgDir = "E:\stitch_img"

# 設定刪除檔案的天數
$saveImgDays = 2
$stitchImgDays = 60

# 設定最小磁碟空間（GB）
$minSpaceGB = 20

# 取得使用者的「我的文件」資料夾路徑
$documentsFolder = [Environment]::GetFolderPath("MyDocuments")

# 設定日誌檔案路徑
$logDate = (Get-Date).ToString("yyyyMMdd")
$logFile = Join-Path -Path $documentsFolder -ChildPath "cleanup_log_$logDate.log"

# 顯示初始磁碟空間
$disks = Get-WmiObject -Class Win32_LogicalDisk
foreach ($disk in $disks) {
    if ($disk.DeviceID -eq "D:") {
        $freeSpaceGB = [math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'D:' }).FreeSpace / 1GB, 0)
        Write-Host "目前磁碟 D 空間：剩餘 $freeSpaceGB GB"
        Add-Content -Path $logFile -Value "目前磁碟 D 空間：剩餘 $freeSpaceGB GB"
    }    if ($disk.DeviceID -eq "E:") {
        $freeSpaceGB = [math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'E:' }).FreeSpace / 1GB, 0)
        Write-Host "目前磁碟 E 空間：剩餘 $freeSpaceGB GB"
        Add-Content -Path $logFile -Value "目前後磁碟 E 空間：剩餘 $freeSpaceGB GB"
    }
}

Write-Host "開始清理過程..."

# 刪除超過指定天數的檔案
foreach ($dir in $saveImgDirs) {
    Write-Host "正在處理目錄：$dir"
    try {
        Get-ChildItem -Path $dir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$saveImgDays) } | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            Add-Content -Path $logFile -Value "刪除檔案： $($_.FullName) 日期：$($_.LastWriteTime)"
            Write-Host "刪除檔案： $($_.FullName)"
        }
        
        # 刪除空目錄
        Get-ChildItem -Path $dir -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force).Count -eq 0 } | Remove-Item -Force -Recurse
    } catch {
        Write-Host "錯誤：$($_.Exception.Message)"
        Add-Content -Path $logFile -Value "錯誤：$($_.Exception.Message)"
    }
}

Write-Host "完成刪除超過 $saveImgDays 天的檔案..."

Get-ChildItem -Path $stitchImgDir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$stitchImgDays) } | ForEach-Object {
    try {
        Remove-Item -Path $_.FullName -Force
        Add-Content -Path $logFile -Value "刪除檔案：$($_.FullName) 日期：$($_.LastWriteTime)"
        Write-Host "刪除檔案：$($_.Name)"
    } catch {
        Write-Host "錯誤：$($_.Exception.Message)"
        Add-Content -Path $logFile -Value "錯誤：$($_.Exception.Message)"
    }
}

# 刪除 E:\stitch_img 中的空目錄
Get-ChildItem -Path $stitchImgDir -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force).Count -eq 0 } | Remove-Item -Force -Recurse

Write-Host "完成刪除超過 $stitchImgDays 天的檔案..."

# 檢查磁碟空間
$freeSpace = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq "E" }).Free / 1GB

if ($freeSpace -lt $minSpaceGB) {
    Write-Host "磁碟空間不足，開始進一步清理..."
    
    # 刪除 D:\save_img 和 E:\save_img 中的所有檔案
    foreach ($dir in $saveImgDirs) {
        Write-Host "正在刪除目錄 $dir 中的所有檔案..."
        try {
            Get-ChildItem -Path $dir -Recurse -Force | Where-Object { !$_.PSIsContainer } | ForEach-Object {
                Remove-Item -Path $_.FullName -Force
                Add-Content -Path $logFile -Value "刪除檔案：$($_.FullName) 日期：$($_.LastWriteTime)"
                Write-Host "刪除檔案：$($_.Name)"
            }
            
            # 刪除空目錄
            Get-ChildItem -Path $dir -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force).Count -eq 0 } | Remove-Item -Force -Recurse
        } catch {
            Write-Host "錯誤：$($_.Exception.Message)"
            Add-Content -Path $logFile -Value "錯誤：$($_.Exception.Message)"
        }
    }

    # 逐日刪除 E:\stitch_img 中的檔案
    $dateLimit = (Get-Date).AddDays(-1)
    $filesDeleted = $true
    while ($freeSpace -lt $minSpaceGB -and $filesDeleted) {
        Write-Host "正在刪除 $stitchImgDir 中的檔案..."
        $filesDeleted = $false
        Get-ChildItem -Path $stitchImgDir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $dateLimit } | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force
                Add-Content -Path $logFile -Value "刪除檔案：$($_.FullName) 日期：$($_.LastWriteTime)"
                Write-Host "刪除檔案：$($_.Name)"
                $filesDeleted = $true
            } catch {
                Write-Host "錯誤：$($_.Exception.Message)"
                Add-Content -Path $logFile -Value "錯誤：$($_.Exception.Message)"
            }
        }
        
        # 刪除 E:\stitch_img 中的空目錄
        Get-ChildItem -Path $stitchImgDir -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force).Count -eq 0 } | Remove-Item -Force -Recurse
        
        $dateLimit = $dateLimit.AddDays(-1)
        $freeSpace = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq "E" }).Free / 1GB
    }

    if (!$filesDeleted) {
        Write-Host "已經刪除所有檔案，但仍然無法達到 $minSpaceGB GB 的空間。"
    }
}

# 顯示清除後的磁碟空間
$disks = Get-WmiObject -Class Win32_LogicalDisk
foreach ($disk in $disks) {

    if ($disk.DeviceID -eq "D:") {
        $freeSpaceGB = [math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'D:' }).FreeSpace / 1GB, 0)
        Write-Host "清除後磁碟 D 空間：剩餘 $freeSpaceGB GB"
        Add-Content -Path $logFile -Value "清除後磁碟 D 空間：剩餘 $freeSpaceGB GB"
    }    if ($disk.DeviceID -eq "E:") {
        $freeSpaceGB = [math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'E:' }).FreeSpace / 1GB, 0)
        Write-Host "清除後磁碟 E 空間：剩餘 $freeSpaceGB GB"
        Add-Content -Path $logFile -Value "清除後磁碟 E 空間：剩餘 $freeSpaceGB GB"
    }


}


Write-Host "清理完成！"
# Add-Content -Path $logFile -Value "清理完成時間：$(Get-Date)"
Add-Content -Path $logFile -Value ("清理完成時間：{0}" -f (Get-Date))
