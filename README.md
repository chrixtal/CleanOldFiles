# CleanOldFiles
Disk Cleanup Tool This repository contains a PowerShell script designed to automate disk space cleanup processes. It deletes files older than a specified number of days in designated directories and performs additional cleanup if disk space falls below a minimum threshold, ensuring at least 20 GB of available space.



請依照下列步驟進行部屬:

1. 請先將 Power Shell 7 下載好，帶至廠內更新。下載地址在此
2. [https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi](https://github.com/PowerShell/PowerShell/releases/)
3. 在 C 磁碟建立一個目錄 log , 如果已經存在了，請跳過此步驟。
4. 將附件: clean_PWR.zip 解壓縮 後得到檔案: clean_PWR.ps1  和 Run_Me.ps1  複製到 c:\log 內
5. 開啟檔案總管，然後在 c:\log 目錄上按下右鍵，選擇 PowerShell 7 -> Open here as Administrator 


6. 開啟後 輸入 .\Run_Me.ps1  (如下圖) 


7. 按下 Enter 執行後會看到如下畫面，代表執行成功。
