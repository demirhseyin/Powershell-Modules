#
# Script.ps1
#
$postParams = @{
LocationID=1
RoleID=5
TypeeID=1
PlatformID=2
ProjectID=2
}
$Request = Invoke-WebRequest -Uri http://localhost:55724/api/Name -Method POST -Body $postParams
$NameContent=@{
Hostname=$Request.Content
}
$NameContent