<#

.SYNOPSIS
PowerShell Server Reboot Script(Mass)

.DESCRIPTION
The script itself will reboot computers which are included in a text file

.EXAMPLE
./RebootComputers -Path C:\TESTDB.txt

.NOTES
Please check the server names in the text file before the execute script.

.LINK
https://github.com/hseyindemir/PowerShell
#>

 param (
  [Parameter(Mandatory=$true)]
    [string] $Path
   
 )
$Computers= Get-Content $Path
foreach($computer in $Computers)
{

Write-Host $computer Reboot Starting
Restart-Computer -ComputerName $computer -Force -Wait -For PowerShell
Get-Service -ComputerName $computer -Name MSSQLSERVER | Out-String
Write-Host $computer Reboot CompletedD
}