#
# Install SQL Server with Following Components
#SQL Server Management Studio
#SQL Server Database Engine
#SQL Server Patch
#
function Get-PendingReboot{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias("CN","Computer")]
        [String[]]$ComputerName="$env:COMPUTERNAME",
        [String]$ErrorLog
        )

    Begin {  }## End Begin Script Block
    Process {
    Foreach ($Computer in $ComputerName) {
	Try {
	    ## Setting pending values to false to cut down on the number of else statements
	    $CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false
                        
	    ## Setting CBSRebootPend to null since not all versions of Windows has this value
	    $CBSRebootPend = $null
						
	    ## Querying WMI for build version
	    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

	    ## Making registry connection to the local/remote computer
	    $HKLM = [UInt32] "0x80000002"
	    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
						
	    ## If Vista/2008 & Above query the CBS Reg Key
	    If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
		    $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
		    $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"		
	    }
							
	    ## Query WUAU from the registry
	    $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
	    $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
						
	    ## Query PendingFileRenameOperations from the registry
	    $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
	    $RegValuePFRO = $RegSubKeySM.sValue

	    ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
	    $Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
	    $PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

	    ## Query ComputerName and ActiveComputerName from the registry
	    $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")            
	    $CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

	    If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
	        $CompPendRen = $true
	    }
						
	    ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
	    If ($RegValuePFRO) {
		    $PendFileRename = $true
	    }

	    ## Determine SCCM 2012 Client Reboot Pending Status
	    ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
	    $CCMClientSDK = $null
	    $CCMSplat = @{
	        NameSpace='ROOT\ccm\ClientSDK'
	        Class='CCM_ClientUtilities'
	        Name='DetermineIfRebootPending'
	        ComputerName=$Computer
	        ErrorAction='Stop'
	    }
	    ## Try CCMClientSDK
	    Try {
	        $CCMClientSDK = Invoke-WmiMethod @CCMSplat
	    } Catch [System.UnauthorizedAccessException] {
	        $CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
	        If ($CcmStatus.Status -ne 'Running') {
	            Write-Warning "$Computer`: Error - CcmExec service is not running."
	            $CCMClientSDK = $null
	        }
	    } Catch {
	        $CCMClientSDK = $null
	    }

	    If ($CCMClientSDK) {
	        If ($CCMClientSDK.ReturnValue -ne 0) {
		        Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"          
		    }
		    If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
		        $SCCM = $true
		    }
	    }
            
	    Else {
	        $SCCM = $null
	    }

	    ## Creating Custom PSObject and Select-Object Splat
	    $SelectSplat = @{
	        Property=(
	            'Computer',
	            'CBServicing',
	            'WindowsUpdate',
	            'CCMClientSDK',
	            'PendComputerRename',
	            'PendFileRename',
	            'PendFileRenVal',
	            'RebootPending'
	        )}
	    New-Object -TypeName PSObject -Property @{
	        Computer=$WMI_OS.CSName
	        CBServicing=$CBSRebootPend
	        WindowsUpdate=$WUAURebootReq
	        CCMClientSDK=$SCCM
	        PendComputerRename=$CompPendRen
	        PendFileRename=$PendFileRename
	        PendFileRenVal=$RegValuePFRO
	        RebootPending=($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
	    } | Select-Object @SelectSplat

	} Catch {
	    Write-Warning "$Computer`: $_"
	    ## If $ErrorLog, log the file to a user specified location/path
	    If ($ErrorLog) {
	        Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
	    }				
	}			
   }## End Foreach ($Computer in $ComputerName)			
 }## End Process

 End {  }## End End

}## End Function Get-PendingReboot

function fnReboot {
    param([Parameter(Mandatory=$true)][string]$ComputerName)
    try {  
        [string]$reboot = (Get-PendingReboot -ComputerName $ComputerName | Select-Object RebootPending | Format-Table -HideTableHeaders | Out-String).Trim()
        Write-Host "Reboot Pending: $reboot"
        if ($reboot -eq "True") {
            Write-Host "$ComputerName restartig..."
            Restart-Computer -ComputerName $ComputerName -Wait -Force
            Write-Host "$ComputerName restarted."
        }
    }
    catch {
        $ErrorMsg = $_.Exception.Message
        return "FAILED - fnReboot - $ErrorMsg"
    }
}

function Copy-File {
    param( [string]$from, [string]$to)
    $ffile = [io.file]::OpenRead($from)
    $tofile = [io.file]::OpenWrite($to)
    Write-Progress -Activity "Copying file" -status "$from -> $to" -PercentComplete 0
    try {
        [byte[]]$buff = new-object byte[] 4096
        [decimal]$total = [decimal]$count = 0
        do {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            if ($total % 1mb -eq 0) {
                Write-Progress -Activity "Copying file" -status "$from -> $to" `
                   -PercentComplete ([decimal]($total/$ffile.Length* 100))
            }
        } while ($count -gt 0)
    }
    finally {
        $ffile.Dispose()
        $tofile.Dispose()
        Write-Progress -Activity "Copying file" -Status "Ready" -Completed
    }
}

$SetupFiles = @()


$SetupFiles += "\\fileserver\03_IT\05_INSTALLERS\01_Installers\MSDN\SQLServer\2016\SW_DVD9_NTRL_SQL_Svr_Ent_Core_2016w_SP1_64Bit_English_OEM_VL_X21-22132.ISO"
$SetupFiles += "\\fileserver\03_IT\05_INSTALLERS\01_Installers\MSDN\SQLServer\2016\SQLServer2016-KB4019916-x64 - SP1 CU3.exe"
$SetupFiles += "\\fileserver\03_IT\05_INSTALLERS\01_Installers\MSDN\SQLServer\2016\SQL Server Management Studio 16.5.3.exe"

$DestinationPath = "\\t-sqldev\s$\setup"

foreach ($item in $SetupFiles) {if (!(Test-Path -Path $item)) {Write-Host "File not found: $item"}}
if (!(Test-Path $DestinationPath)) {New-Item -ItemType Directory -Path $DestinationPath}

foreach ($item in $SetupFiles) {
	$outputFile = Split-Path $item -leaf
	#Copy-File -from $item -to "$DestinationPath\$outputFile"
}

#Copy-Item "C:\Users\ahmet.rende\Dropbox\SQL\Powershell\SQL Auto Silent Install\SQL2016_Config.ini" \\t-sqldev\s$\setup

fnReboot -ComputerName t-sqldev

Invoke-Command -ComputerName t-sqldev -ScriptBlock {Mount-DiskImage -ImagePath "s:\setup\SW_DVD9_NTRL_SQL_Svr_Ent_Core_2016w_SP1_64Bit_English_OEM_VL_X21-22132.ISO"}

Set-Location  C:\Users\ahmet.rende\Downloads\PSTools
Write-Host "installing sql setup"
.\PsExec.exe \\t-sqldev -h -s E:\setup.exe /SQLSVCPASSWORD="SQL@Svc*-+" /AGTSVCPASSWORD="SQL@Svc*-+" /SAPWD="Trendyol1" /Q /IAcceptSQLServerLicenseTerms /CONFIGURATIONFILE="s:\setup\SQL2016_Config.ini"
Write-Host "installed sql setup"
fnReboot -ComputerName t-sqldev
Write-Host "installing sql patch"
.\PsExec.exe \\t-sqldev -h -s "s:\setup\SQLServer2016-KB4019916-x64 - SP1 CU3" /allinstances /quiet /IAcceptSQLServerLicenseTerms /Action=Patch
Write-Host "installed sql patch"
fnReboot -ComputerName t-sqldev
Write-Host "installing ssms"
.\PsExec.exe \\t-sqldev -h -s "s:\setup\SQL Server Management Studio 16.5.3.exe" /install /quiet /norestart
Write-Host "installed ssms"

