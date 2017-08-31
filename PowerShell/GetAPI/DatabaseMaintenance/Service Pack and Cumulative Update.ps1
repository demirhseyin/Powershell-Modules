#
# Service_Pack_and_Cumulative_Update.ps1
#
param (

    [Parameter(Mandatory=$true)]
    [string] $ComputerList,
    
    [Parameter(Mandatory=$true)]
    [string] $Exe
 )
Function TestReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
} 
Function FindLastRebootTime
 {
 Get-WmiObject win32_operatingsystem | select csname, @{LABEL=’LastBootUpTime’;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
 }
Function Last-Reboot-Time
{
param (

    [Parameter(Mandatory=$true)]
    [string] $ComputerList
 )

Write-Host Last Reboot Times of Server -ForegroundColor Green
$Computers= Get-Content $ComputerList
foreach($computer in $Computers)
{
Invoke-Command -ComputerName $computer -ScriptBlock ${function:FindLastRebootTime}

}
}

Function MainPatchFunction
{
$PatchResult #PatchResultVariable

$Computers= Get-Content $ComputerList
Clear-Content -Path C:\DBA\ComputerReboot.txt
foreach($computer in $Computers)
{
$session=New-PSSession -ComputerName $computer
$result = Invoke-Command -ComputerName $computer -ScriptBlock ${function:TestReboot}
if ($result -eq 1)
{
#Apped the Computer Name to TXT file

if (!(Test-Path "C:\DBA\ComputerReboot.txt"))
{
   New-Item -path C:\DBA -name ComputerReboot.txt
   $computer.ToString() | Out-File C:\DBA\ComputerReboot.txt -Append
   #Delete!
Invoke-Command -Session $session -ScriptBlock ${function:PatchFunction} -JobName "Patch" -AsJob
Wait-Job -Name "Patch"
}
else
{
$computer.ToString() | Out-File C:\DBA\ComputerReboot.txt -Append
#Delete!
Invoke-Command -Session $session -ScriptBlock ${function:PatchFunction} -JobName "Patch" -AsJob
Wait-Job -Name "Patch"

}

}
else
{
#SQL Patch
 Invoke-Command -Session $session -ScriptBlock ${function:PatchFunction}

}
}
}

Function PatchFunction()
{
$exe = 'C:\DBA\sql2014_sp2_cu6.exe'
$Exe -replace ' ', '` '

& $exe /quiet /action=patch /allinstances /IAcceptSQLServerLicenseTerms
}

#Last-Reboot-Time
MainPatchFunction

