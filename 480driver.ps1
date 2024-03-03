Import-Module '/home/jacob/SYS480/modules/480-utils' -Force
# Call the Banner Function
480Banner

# Set the configuration file path to our .json
$conf = Get-480Config -config_path "/home/jacob/SYS480/480.json"
480Connect -server $conf.vcenter_server # Connect to my vcenter


# Now after the user sees the different folders/VMs seeded inside, they can decide what VM to interact with! 
Write-Host "Selecting your VM" 
$VM_variable = Select-VM -folder 'BASEVM'

# Select datastore! 
$datastore_variable = Select-Datastore

# Select Snapshot
$snapshot_variable = Select-Snapshot

# Testing new clone
$clone_var = new_clone -vm $VM_variable -ds $datastore_variable -snap $snapshot_variable
