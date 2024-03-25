# Establish the Connection to the server!
$vcenter = "vcenter.jacob.local"
Connect-VIServer($vcenter)

# Check if the connection is established
if ($?) {
    Write-Host "Connected to $vcenter."
} else {
    Write-Host "Failed to connect to $vcenter. Exiting script."
    exit
}

# Get the list of VMs and prompt user to select one
$vmList = Get-VM | Select-Object -ExpandProperty Name
$vmName = Read-Host "Enter the VM name to clone (select from the list: $($vmList -join ', '))"

# Check if the entered VM name is valid
if ($vmList -notcontains $vmName) {
    Write-Host "Invalid VM name. Exiting script."
    Disconnect-VIServer -Server $vcenter -Confirm:$false
    exit
}

# Assign variables

$snapshotName = "Base"
$datastoreName = "datastore1-super24"
$vmHostName = "192.168.7.34"

# Get VM, snapshot, VMHost, and Datastore
$vm = Get-VM -Name $vmName
$snapshot = Get-Snapshot -VM $vm -Name $snapshotName
$vmhost = Get-VMHost -Name $vmHostName
$datastore = Get-Datastore -Name $datastoreName

# Check if the snapshot is found
if ($snapshot -eq $null) {
    Write-Host "Snapshot '$snapshotName' not found for VM $vmName. Exiting script."
} else {
    # Generate linked clone name
    $linkedCloneName = Read-Host "Enter the name for the linked clone VM"

    # Create the linked clone
    $linkedVM = New-VM -LinkedClone -Name $linkedCloneName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $datastore
    Write-Host "Linked clone created successfully for VM $vmName."

    # Take a snapshot of the new base VM
    $linkedVM | New-Snapshot -Name "Base"
    Write-Host "Snapshot 'Base' created for the new base VM."
}

# Disconnect from the vCenter server
Disconnect-VIServer -Server $vcenter -Confirm:$false
