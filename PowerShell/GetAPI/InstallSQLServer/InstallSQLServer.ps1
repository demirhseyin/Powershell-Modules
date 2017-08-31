<#

.SYNOPSIS
SQL Installer

.DESCRIPTION
The script itself install SQL Server that is defined by ComputerName and SetupPath

.NOTES
Please check the setup file and the path

.LINK
https://github.com/hseyindemir/PowerShell
#>

 param (
  [Parameter(Mandatory=$true)]
    [string]$ComputerName,
[Parameter(Mandatory=$true)]
    [string]$ISOPath,
[Parameter(Mandatory=$true)]
    [string]$PSToolsPath
 )
Function MountISOFile{
try{
Write-Host Mounting ISO File -ForegroundColor DarkYellow
Invoke-Command -ComputerName $ComputerName -ScriptBlock {Mount-DiskImage -ImagePath $ISOPath}
Write-Host Mounted ISO File -ForegroundColor Green
}
catch [Exception] {
echo $_.Exception.GetType().FullName, $_.Exception.Message
}
}
Function InstallSQLServer{
try{
Write-Host SQL Server Installation Starting... -ForegroundColor DarkYellow
Set-Location  $PSToolsPath
.\PsExec.exe \\$ComputerName -h -s #Setup Path and Arguments
Write-Host SQL Server Installed -ForegroundColor Green
}
catch [Exception] {
echo $_.Exception.GetType().FullName, $_.Exception.Message
}
}

MountISOFile
InstallSQLServer



