param (

    [Parameter(Mandatory=$true)]
    [string] $ComputerList,
     [Parameter(Mandatory=$true)]
    [string] $ReportPath
 )


Function GetDiskReport()
{
gwmi win32_logicaldisk | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}
}
Function CollectReport()
{
$Computers= Get-Content $ComputerList
foreach($computer in $Computers)
{
$computer >> $ReportPath
$Session = New-PSSession -ComputerName $computer
$Disksizes = Invoke-Command -Session $Session -ScriptBlock ${function:GetDiskReport}
$Disksizes >> $ReportPath
}
}

CollectReport