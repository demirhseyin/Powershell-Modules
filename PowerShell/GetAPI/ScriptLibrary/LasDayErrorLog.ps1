#
# LasDayErrorLog.ps1
#

 param (
  [Parameter(Mandatory=$true)]
    [string]$computerName
   
 )
$yesterday = (Get-Date).AddHours(-24)
$ErrWarn4App = Get-WinEvent -ComputerName $computerName -FilterHashTable @{LogName='Application'; Level=2; StartTime=$yesterday} -ErrorAction SilentlyContinue | Select-Object TimeCreated,ProviderName,LevelDisplayName,Message
$ErrWarn4App | Sort TimeCreated |ConvertTo-Csv| Out-File -filepath C:\ErrorLogsLastDay.csv
$ErrWarn4App | Sort TimeCreated |ConvertTo-Html| Out-File -filepath C:\ErrorLogsLastDay.html


