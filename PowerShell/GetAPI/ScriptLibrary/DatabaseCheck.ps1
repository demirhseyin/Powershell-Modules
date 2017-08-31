 param (
 [Parameter(Mandatory=$true)]
    [string] $ComputerListPath,
     [Parameter(Mandatory=$true)]
    [string] $ReportPath
 )

 function Get_Versions
 {

$Computers= Get-Content $ComputerListPath

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
	#test
}
}
}
function MiniCheck
{
if (!(Test-Path $ReportPath))

{
New-Item $ReportPath
}
else
{
Clear-Content $ReportPath
}

Write-Host Generating a Report for Databases... -ForegroundColor Green
try
{
foreach ($svr in get-content $ComputerListPath)
{
$svr | Out-File $ReportPath -Append
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $svr
     $dbs=$s.Databases       
     $dbs | SELECT Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable | Out-File C:\DBA\Report.txt -Append

$result = Invoke-Sqlcmd -ServerInstance $svr -InputFile C:\HealthCheck\HealthCheck\Scripts_2014\Version.sql
$result |Format-Table |Out-File $ReportPath -Append
$result = Invoke-Sqlcmd -ServerInstance $svr -InputFile C:\HealthCheck\HealthCheck\Scripts_2014\CPU_Pressure.sql
$result |Format-Table |Out-File $ReportPath -Append
$result = Invoke-Sqlcmd -ServerInstance $svr -InputFile C:\HealthCheck\HealthCheck\Scripts_2014\ServerConfig.sql
$result |Format-Table |Out-File $ReportPath -Append
$result = Invoke-Sqlcmd -ServerInstance $svr -InputFile C:\HealthCheck\HealthCheck\Scripts_2014\IO_Stats.sql
$result |Format-Table |Out-File $ReportPath -Append
}
Write-Host Report Generated "->" $ReportPath -ForegroundColor Green
}
catch
{
Write-Host Report Could NOT Generated "->" $ReportPath -ForegroundColor Red
}
}

Get_Versions
Minicheck