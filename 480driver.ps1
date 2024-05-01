Import-Module '/home/jacob/SYS480/modules/480-utils' -Force
# Call the Banner Function
480Banner

# Set the configuration file path to our .json
$conf = Get-480Config -config_path "/home/jacob/SYS480/480.json"
480Connect -server $conf.vcenter_server # Connect to my vcenter


# Select VM 
Write-Host "Selecting your VM" 
$VM_variable = Select-VM

# Select datastore! 
$datastore_variable = Select-Datastore

# Select Snapshot
$snapshot_variable = Select-Snapshot

# Prompt user if they want to create a new clone
$createCloneResponse = Read-Host "Do you want to create a new clone for the selected VM? (Y/N)"
if ($createCloneResponse -eq "Y") {
    # Testing new clone
    $clone_var = New_Clone -vm $VM_variable -ds $datastore_variable -snap $snapshot_variable
} elseif ($createCloneResponse -eq "N") {
    Write-Host "Skipping creation of a new clone for the selected VM."
}

# Prompt user if they want to manage power
$managePowerResponse = Read-Host "Do you want to manage power for the selected VM? (Y/N)"
if ($managePowerResponse -eq "Y") {
    # Manage Power Function - Start, Stop, Restart VM
    Manage_Power
} elseif ($managePowerResponse -eq "N") {
    Write-Host "Skipping power management for the selected VM."
}

# Prompt user if they want to set network
$setNetworkResponse = Read-Host "Do you want to set the network for the selected VM? (Y/N)"
if ($setNetworkResponse -eq "Y") {
    # Set Network Function - Set network for a VM's network adapter
    Set-Network
} elseif ($setNetworkResponse -eq "N") {
    Write-Host "Skipping network configuration for the selected VM."
}

# Prompt user if they want to get IP information
$getIPResponse = Read-Host "Do you want to retrieve IP information for the selected VM? (Y/N)"
if ($getIPResponse -eq "Y") {
    # Get IP Function - Retrieve IP address and MAC address for a VM
    Get-IP
} elseif ($getIPResponse -eq "N") {
    Write-Host "Skipping IP information retrieval for the selected VM."
}