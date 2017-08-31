#
# MountISOFile.ps1
#
 param (
  [Parameter(Mandatory=$true)]
    [string]$ComputerName,
[Parameter(Mandatory=$true)]
    [string]$ISOPath
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
