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
Function CollectOSInformation()
{

$CPUInfo = Get-WmiObject Win32_Processor #Get CPU Information 
$OSInfo = Get-WmiObject Win32_OperatingSystem #Get OS Information 
#Get Memory Information. The data will be shown in a table as MB, rounded to the nearest second decimal. 
$OSTotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2) 
$OSTotalVisibleMemory = [math]::round(($OSInfo.TotalVisibleMemorySize  / 1MB), 2) 
$PhysicalMemory = Get-WmiObject CIM_PhysicalMemory | Measure-Object -Property capacity -Sum | % {[math]::round(($_.sum / 1GB),2)} 
$infoObject = New-Object PSObject 
#The following add data to the infoObjects. 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPUInfo.SystemName 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Name" -value $CPUInfo.Name 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Description" -value $CPUInfo.Description 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Manufacturer" -value $CPUInfo.Manufacturer 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_NumberOfCores" -value $CPUInfo.NumberOfCores 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L2CacheSize" -value $CPUInfo.L2CacheSize 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L3CacheSize" -value $CPUInfo.L3CacheSize 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_SocketDesignation" -value $CPUInfo.SocketDesignation 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value $OSInfo.Caption 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value $OSInfo.Version 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical_Memory_GB" -value $PhysicalMemory 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVirtual_Memory_MB" -value $OSTotalVirtualMemory 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVisable_Memory_MB" -value $OSTotalVisibleMemory 
$infoObject | Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
}

Function GetDatabaseLogError()
{
Get-EventLog -LogName "application" -Newest 20 | Where-Object {$_.source -like "*SQL*"} | Where-Object {$_.EntryType -eq "Error"}
}

Function CollectReport()
{
$Computers= Get-Content $ComputerList
foreach($computer in $Computers)
{
$computer >> $ReportPath
$Session = New-PSSession -ComputerName $computer
$Disksizes = Invoke-Command -Session $Session -ScriptBlock ${function:GetDiskReport}
$OSInformation = Invoke-Command -Session $Session -ScriptBlock ${function:CollectOSInformation}
$Logs =  Invoke-Command -Session $Session -ScriptBlock ${function:GetDatabaseLogError}
$OSInformation >> $ReportPath
$Disksizes >> $ReportPath
$LogMessage = "Database Error Logs"
$End = "---------------------------------------------------------------------------------------------"
$LogMessage >> $ReportPath
$Logs >> $ReportPath
$End >> $ReportPath
}
}



Function ConvertTo-PDFFile
{
    Param
    (
        [string]$Source,
        [string]$Destionation
    )
 
    #Get the content of the file.
    $Source = Get-Content $Source -Encoding UTF8;
 
    #Required Word Variables.
    $ExportFormat = 17;
    $SaveOption = 0
 
    #Create a hidden Word window.
    $WordObject = New-Object -ComObject word.application;
    $WordObject.Visible = $false;
 
    #Add a Word document.
    $DcoumentObject = $WordObject.Documents.Add();
 
    #Put the text into the Word document.
    $WordSelection = $WordObject.Selection;
    $WordSelection.TypeText($Source);
 
    #Set the page orientation to landscape.
    $DcoumentObject.PageSetup.Orientation = 1;
 
    #Export the PDF file and close without saving a Word document.
    $DcoumentObject.ExportAsFixedFormat($Destionation,$ExportFormat);
    $DcoumentObject.close([ref]$SaveOption);
    $WordObject.Quit();
}


CollectReport
#ConvertTo-PDFFile -Source $ReportPath -Destionation "C:\DBA\Report.pdf"

