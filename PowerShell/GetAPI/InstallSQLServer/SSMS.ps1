<#

.SYNOPSIS
PowerShell Server Reboot Script(Mass)

.DESCRIPTION
The script itself install SQL Server Management Studio that is defined by ComputerName and SetupPath

.EXAMPLE
./SSMS -ComputerName SERVERNAME -SetupPath c:\SSMS.exe -PSToolsPath C:\TTE\PSTools

.NOTES
Please check the setup file and the path

.LINK
https://github.com/hseyindemir/PowerShell
#>

 param (
  [Parameter(Mandatory=$true)]
    [string]$ComputerName,
    [Parameter(Mandatory=$true)]
    [string]$SetupPath,
	[Parameter(Mandatory=$true)]
    [string]$PSToolsPath
 )

Set-Location  $PSToolsPath
$Result=.\PsExec.exe \\$ComputerName -h -s $SetupPath /install /quiet /norestart

if($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010){
Write-Host "SQL Server Management Studio Installed Successfully"
Write-Host Return Code:$LASTEXITCODE
}
else
{
Write-Host $LASTEXITCODE
}

