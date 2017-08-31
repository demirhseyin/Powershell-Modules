#
# InstallSQLServer.ps1
#
param (
 [Parameter(Mandatory=$true)]
    [string] $ComputerListPath,
     [Parameter(Mandatory=$true)]
    [string] $SetuPath
 )
Function NETFramework
{
Import-Module ServerManager


Add-WindowsFeature Net-Framework-Core

}

Function SQLInstall
{

$Computers= Get-Content $ComputerListPath
foreach($computer in $Computers)
{

$session=New-PSSession -ComputerName $computer
Invoke-Command -Session $session -ScriptBlock {Start-Process -Verb runas -FilePath $SetuPath -ArgumentList /ConfigurationFile="C:\DBA\ConfigFile.ini" -Wait}
}
}