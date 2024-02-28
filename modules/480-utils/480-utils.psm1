function 480Banner()
{
    Write-Host "Hello SYS480-DevOps!"
}

function 480Connect([string] $server)
{
    $connection = $global:DefaultVIServer
    # Questions if we are connected or not: 
    if ($connection){
        $msg = "Already Connected to: {0}" -f $connection

        Write-Host -ForegroundColor Green $msg
    }else {
        $connection = Connect-VIServer -Server $server 
    }
}

function Get-480Config([string]$config_path) 
{
    Write-Host "Reading " $config_path
    $conf=$null
    if(Test-Path $config_path)
    {
        $conf= (Get-Content -Path $config_path -Raw | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor Green $msg
    } else
    {
        Write-Host "No configuration found at $config_path" -ForegroundColor Yellow
    }
    return $conf
}

# Function Select-VM([string] $folder)
# {
#     $selected_vm=$null
#     try 
#     {
#         $vms = Get-VM -Location $folder
#         $index = 1
#         # The for loop below is writing the index + 1 and the VM name. 
#         foreach($vm in $vms)
#         {
#             Write-Host [$index] $vm.name
#             $index+=1
#         }
#         $pick_index = Read-Host "Which index number [x] do you wish to pick?"
#         # 480-TODO Need to deal with an invalid index (consider making this check a function)
#         $selected_vm = $vms[$pick_index -1]
#         Write-Host "You picked " $selected_vm.Name
#         # note this is a full on vm object that we can interract with!
#         return $selected_vm    
#     }
#     catch 
#     {
#         Write-Host "Invalid Folder: $folder" -ForegroundColor Red    <#Do this if a terminating exception happens#>
#     }
        
# }

# I may be weird but I just copied the function that was provided to us, then enhanced it below. I commented out the original function for future reference. 
Function Select-VM([string] $folder)  
{
    $selected_vm = $null

    try 
    {
        # Retrieve list of VMs in the specified folder
        $vms = Get-VM -Location $folder

        if ($vms.Count -eq 0) {
            # Inform user if no VMs are found
            Write-Host "No virtual machines found in $folder" -ForegroundColor Yellow
            return $null
        }

        # Display the list of VMs with indices
        $index = 1
        foreach ($vm in $vms)
        {
            Write-Host "[$index] $($vm.Name)"
            $index++
        }

        # Loop until a valid index value is entered
        do {
            # Prompt the user to enter the index number of the VM they wish to select
            $pick_index = Read-Host "Enter the index number of the VM you wish to select"

            # Check if the input is a number and within the range of available indices
            if ($pick_index -ge 1 -and $pick_index -le $vms.Count) {
                # Retrieve the selected VM based on the index
                $selected_vm = $vms[$pick_index - 1]
                Write-Host "You picked $($selected_vm.Name)"
            } else {
                # Inform the user of an invalid index and prompt again
                Write-Host "Invalid index. Please enter a valid index between 1 and $($vms.Count)" -ForegroundColor Red
            }
        } while (-not $selected_vm)  # Continue the loop until a valid VM is selected

        return $selected_vm
    }
    catch 
    {
        # Handles errors that occur during VM selection
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-Folder() {
    $folder_selected = $null

    try {
        $folders = Get-Folder
        $index = 1

        # Display the list of folders with their index
        foreach ($folder in $folders) {
            Write-Host "[$index] $($folder.Name)"
            $index += 1
        }

        while ($true) {
            # Prompt user to enter the index number of the folder
            $pick_index = Read-Host "Enter the index number of the folder you wish to select"

            # Validate if the input is a valid number and within the range
            if ($pick_index -match '^\d+$' -and $pick_index -ge 1 -and $pick_index -le $folders.Count) {
                $folder_selected = $folders[$pick_index - 1]
                Write-Host "You picked folder: $($folder_selected.Name)"
                
                # Retrieve the contents of the selected folder
                $folderContents = Get-VM -Location $folder_selected
                Write-Host "Contents of the folder:"
                $folderContents | Format-Table Name, PowerState, NumCpus, MemoryGB -AutoSize
                
                return $folder_selected
            } else {
                Write-Host "Invalid index. Please enter a valid index."
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-Datastore() {
    $datastore_selected = $null
    # Take a snapshot of the 

    try {
        $datastores = Get-Datastore
        $index = 1

        # Display the list of datastores with their index
        foreach ($datastore in $datastores) {
            Write-Host "[$index] $($datastore.Name)"
            $index += 1
        }

        while ($true) {
            # Prompt user to enter the index number of the datastore
            $pick_index = Read-Host "Enter the index number of the datastore you wish to select"

            # Validate if the input is a valid number and within the range
            if ($pick_index -match '^\d+$' -and $pick_index -ge 1 -and $pick_index -le $datastores.Count) {
                $datastore_selected = $datastores[$pick_index - 1]
                Write-Host "You picked datastore: $($datastore_selected.Name)"
                
                # Retrieve the contents of the selected datastore
                $datastoreContents = Get-VM -Datastore $datastore_selected
                Write-Host "Contents of the datastore:"
                $datastoreContents | Format-Table Name, PowerState, NumCpus, MemoryGB -AutoSize
                
                return $datastore_selected
            } else {
                Write-Host "Invalid index. Please enter a valid index."
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-Snapshot() {
    $snapshot_selected = $null

    try {
        $vms = Get-VM
        $snapshots = @()

        # Collect snapshots from all VMs
        foreach ($vm in $vms) {
            $snapshots += Get-Snapshot -VM $vm
        }

        $index = 1

        # Display the list of snapshots with their index
        foreach ($snapshot in $snapshots) {
            Write-Host "[$index] $($snapshot.Name) - VM: $($snapshot.VM.Name)"
            $index += 1
        }

        while ($true) {
            # Prompt user to enter the index number of the snapshot
            $pick_index = Read-Host "Enter the index number of the snapshot you wish to select"

            # Validate if the input is a valid number and within the range
            if ($pick_index -match '^\d+$' -and $pick_index -ge 1 -and $pick_index -le $snapshots.Count) {
                $snapshot_selected = $snapshots[$pick_index - 1]
                Write-Host "You picked snapshot: $($snapshot_selected.Name) - VM: $($snapshot_selected.VM.Name)"
                
                return $snapshot_selected 
                # Write-Host $snapshot_selected
            } else {
                Write-Host "Invalid index. Please enter a valid index."
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function new_clone([string] $vm, $snap, $ds)
{
    try {
        if ($snapshot_selected) {
            Write-Host "Snapshot not found for VM $($selected_vm.Name). Exiting script."
        } else {
            # Debug information
            $ds = $ds.Name
            Write-Host "Selected VM: $($vm)"
            Write-Host "Selected Snapshot: $($snap)"
            Write-Host "Selected Datastore: $($ds)"

            # Prompt the user for the new clone name
            $cloneName = Read-Host "Enter the new clone name"

            Write-Host $vm $ds $snap $conf.esxi_host

            
            # Create the linked clone
            $linkedVM = New-VM -LinkedClone -Name "$($cloneName).linked" -VM $vm -ReferenceSnapshot $snap -VMHost $conf.esxi_host -Datastore $ds 

            # Debug information
            Write-Host "Linked clone created successfully: $($cloneName).linked"
            $test = Get-VM -Name "$($cloneName).linked"
            $test


            # Retrieve the linked VM 
            $linkedVM = Get-VM -Name "$($cloneName)"
            if ($null -eq $linkedVM) {
                Write-Host "Linked clone not found. Exiting script."
                return
            }
            
            # Debug information
            Write-Host "Linked clone retrieved successfully: $($cloneName)"

            Write-Host $vm $ds $snap $conf.esxi_host

            # Create a new base VM from the linked clone
            Write-Host "Creating new base VM: $($cloneName)..."
            $newVM = New-VM -Name $cloneName -VM $linkedVM -Datastore $ds -ReferenceSnapshot $snap -VMHost $conf.esxi_host
            
            # Debug information
            Write-Host "New base VM '$($cloneName)' created successfully."

            # Take a snapshot of the new base VM
            Write-Host "Taking snapshot 'Base' for new base VM..."
            $newVM | New-Snapshot -Name "Base"
            Write-Host "Snapshot 'Base' created for the new base VM."

            # Remove the linked clone
            Write-Host "Removing linked clone: $($linkedVM.Name)..."
            $linkedVM | Remove-VM -Confirm:$false
            Write-Host "Linked clone removed successfully."
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
