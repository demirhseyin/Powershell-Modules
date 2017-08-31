#
# GetDatabaseVersion.ps1
#
 param (
 [Parameter(Mandatory=$true)]
    [string] $ComputerListPath
 )

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
Write-Host Can Not Retrieve The Version for $computer -BackgroundColor Yellow -ForegroundColor DarkRed
}
}
