Import-Module '/home/jacob/SYS480/modules/480-utils' -Force
# Call the Banner Function
480Banner

# Set the configuration file path to our .json
$conf = Get-480Config -config_path = "/home/jacob/SYS480/480.json"
480Connect -server $conf.vcenter_server # Connect to my vcenter

# Select-folder function in use
Write-Host "Select your Folder to see the contents of it"  
Select-Folder 

# Now after the user sees the different folders/VMs seeded inside, they can decide what VM to interact with! 
Write-Host "Selecting your VM" 
Select-VM -folder 'BASEVM'

# Select datastore! 
Select-Datastore

# Select Snapshot
Select-Snapshot