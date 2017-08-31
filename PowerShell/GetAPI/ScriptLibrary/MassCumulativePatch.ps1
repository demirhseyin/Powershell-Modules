#Main Parameters
param (
 [Parameter(Mandatory=$true)]
    [string] $ComputerListPath,
     [Parameter(Mandatory=$true)]
    [string] $FileName
 )

 #ISO File = Fileserver -> Local Computer
 Function CopyISO
{
$Computers= Get-Content $ComputerListPath

foreach($computer in $Computers)
{

$Path= "#Path\$FileName"
If (Test-Path $Path)
{
  Write-Host File $FileName Exist and Copy is Starting... for $computer
  Copy-Item -Path #Path\$FileName -Destination \\$computer\c$\DBA\
  Write-Host File $FileName Copy Process Finished for $computer
}
Else
{
 Write-Host File $FileName Does NOT! Exist
}
}
}

#Check the Version of SQL Database
 function GetVersions
 {
$Computers= Get-Content $ComputerListPath
Write-Host Database Path Level
foreach($computer in $Computers)
{
try
{
$session=New-PSSession -ComputerName $computer
Invoke-Command -Session $session -ScriptBlock {Invoke-Sqlcmd -Query "SELECT @@VERSION;"}
}
catch
{
Write-Host Can Not Retrieve The Version for $computer -ForegroundColor Red
}
}
}

#Patch the SQL Server Databases
Function CumulativePatch
{
$Computers= Get-Content $ComputerListPath
Write-Host $PatchName
foreach($computer in $Computers)
{
$session=New-PSSession -ComputerName $computer
Invoke-Command -Session $session -ScriptBlock {C:\DBA\sql2016_sp1_cu4.exe /q /action=patch /allinstances /IAcceptSQLServerLicenseTerms}
Write-Host Started Cumulative Update for $computer
}
}

#Process->Flow
CopyISO
GetVersions
CumulativePatch



#V2

param (
 [Parameter(Mandatory=$true)]
    [string] $Path
 )
 Function PathSQLSP($string)
 {

 &$string /q /action=patch /allinstances /IAcceptSQLServerLicenseTerms

 }


 function Test-PendingReboot
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
function Last-Reboot-Time
{

 Get-WmiObject win32_operatingsystem | select csname, @{LABEL=’LastBootUpTime’;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}
$Computers= Get-Content C:\TESTDB.txt
foreach($computer in $Computers)
{
Write-Host $computer
Invoke-Command -ScriptBlock ${function:Test-PendingReboot} -ComputerName $computer
}

Test-PendingReboot
#PathSQLSP($Path)



#V3

param (

     [Parameter(Mandatory=$true)]
    [string] $ComputerListPath
)
 Function PathSQLSP()
 {

 $Computers= Get-Content $ComputerListPath
Write-Host $PatchName
foreach($computer in $Computers)
{
$session=New-PSSession -ComputerName $computer
Invoke-Command -Session $session -ScriptBlock {C:\DBA\sql2016_sp1_cu4.exe /quiet /action=patch /allinstances /IAcceptSQLServerLicenseTerms}
Write-Host Started Cumulative Update for $computer
}
}