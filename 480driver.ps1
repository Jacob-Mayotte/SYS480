Import-Module '/home/jacob/SYS480/modules/480-utils' -Force
# Call the Banner Function
480Banner
$conf = Get-480Config -config_path = "/home/jacob/SYS480/480.json"
480Connect -server $conf.vcenter_server
Write-Host "Selecting your VM"
Select-VM -folder 'BASEVM'
