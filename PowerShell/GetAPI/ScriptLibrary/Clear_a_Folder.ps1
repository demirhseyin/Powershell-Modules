#
# Clear_a_Folder.ps1
#
$startFolder="C:\Users\huseyin.demir\Downloads"#Directory
$colItems = Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object
foreach ($i in $colItems)
{
    $subFolderItems = Get-ChildItem $i.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
    $i.FullName + " -- " + "{0:N2}" -f ($subFolderItems.sum / 1MB) + " MB"
}
Remove-Item C:\Users\huseyin.demir\Downloads\* -recurse -Force