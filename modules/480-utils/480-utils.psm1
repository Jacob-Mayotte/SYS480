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

Function Select-VM([string] $folderName)  
{
    $selected_vms = @()

    try 
    {
        # Retrieve list of VMs in the specified folders
        $folder1 = Get-Folder -Name $conf.vm_folder
        $folder2 = Get-Folder -Name $conf.vm2_folder

        if ($null -eq $folder1 -or $null -eq $folder2) {
            Write-Host "One or more folders not found. Exiting script." -ForegroundColor Red
            return $null
        }

        $vms1 = Get-VM -Location $folder1
        $vms2 = Get-VM -Location $folder2

        if ($vms1.Count -eq 0 -and $vms2.Count -eq 0) {
            # Inform user if no VMs are found in both folders
            Write-Host "No virtual machines found in $folder1 and $folder2" -ForegroundColor Yellow
            return $null
        }

        # Add VMs from folder 1 to the selected VMs array
        $selected_vms += $vms1

        # Add VMs from folder 2 to the selected VMs array
        $selected_vms += $vms2

        # Display list of selected VMs with indices
        $index = 1
        foreach ($vm in $selected_vms)
        {
            Write-Host "[$index] $($vm.Name)"
            $index++
        }

        # Loop until a valid index value is entered
        do {
            # Prompt the user to enter the index number of the VM they wish to select
            $pick_index = Read-Host "Enter the index number of the VM you wish to select"

            # Check if the input is a number and within the range of available indices
            if ($pick_index -ge 1 -and $pick_index -le $selected_vms.Count) {
                # Retrieve the selected VM based on the index
                $selected_vm = $selected_vms[$pick_index - 1]
                Write-Host "You picked $($selected_vm.Name)"
            } else {
                # Inform the user of an invalid index and prompt again
                Write-Host "Invalid index. Please enter a valid index between 1 and $($selected_vms.Count)" -ForegroundColor Red
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

function Select-Datastore() {
    $datastore_selected = $null
     

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

            # Validate if the input is a valid number and within the range of available indices 
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

 
function New_Clone([string] $vm, $snap, $ds)
{
    try {
        if (-not $snap) {
            Write-Host "Snapshot not found for VM $($vm.Name). Exiting script."
        } else {
            # Debug info 
            $ds = $ds.Name
            Write-Host "Selected VM: $($selected_vm)"
            Write-Host "Selected Snapshot: $($snap.Name)"
            Write-Host "Selected Datastore: $($ds)"

            # Prompt user for the new linked clone name
            $cloneName = Read-Host "Enter the new linked clone name"

            # Define the linked clone name
            $linkedCloneName = "$cloneName.linked"

            # Debug info 
            Write-Host $vm $ds $snap $conf.esxi_host

            # Create the linked clone - set to variable/ 
            $linkedVM = New-VM -LinkedClone -Name $linkedCloneName -VM $vm -ReferenceSnapshot $snap -VMHost $conf.esxi_host -Datastore $ds 

            # Debug info 
            Write-Host "Linked clone created successfully: $linkedCloneName"
            $test = Get-VM -Name "$linkedCloneName"
            $test

            # Retrieve the linked VM 
            $linkedVM = Get-VM -Name $linkedCloneName
            if ($null -eq $linkedVM) { # - Error handling too 
                Write-Host "Linked clone not found. Exiting script."
                return
            }

            # Debug info 
            Write-Host "Linked clone retrieved successfully: $($cloneName)"

            Write-Host $vm $ds $snap $conf.esxi_host # Debug Line  to observe variables

            # Create a new base VM from the linked clone using New-VM
            Write-Host "Creating new base VM: $($cloneName)..."
            
            # Specify the folder where the new VM should be created - call from 480.json file
            $folder = Get-Folder -Name $conf.vm_folder
            if ($null -eq $folder) {
                Write-Host "Folder '$($conf.vm_folder)' not found. Exiting script."
                return
            }
            
            # Prompt the user for the new base clone name
            $cloneName = Read-Host "Enter the new base clone name"

            # Clone the linked-VM using the New-VM cmdlet
            $newVM = New-VM -VM $linkedVM -Name $cloneName -VMHost $conf.esxi_host -Location $conf.vm_folder -RunAsync 
            $newVM | Wait-Task

            # Debug information
            Write-Host "New base VM '$cloneName' created successfully."

            # Remove the linked clone
            Write-Host "Removing linked clone: $($linkedVM.Name)..."
            $linkedVM | Remove-VM -Confirm:$false
            Write-Host "Linked clone removed successfully."
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}


function Get-IP 
{
    try 
    {
        # Prompt user to select a VM
        $selectedVM = Select-VM -folderName $conf.vm_folder
        
        if ($selectedVM) {
            # Get the first network adapter of the selected VM
            $networkAdapter = $selectedVM | Get-NetworkAdapter | Select-Object -First 1

            if ($networkAdapter) 
            {
                # Get the IP, VM name, and MAC address
                $ipAddress = $selectedVM.Guest.IPAddress[0]
                $macAddress = $networkAdapter.MacAddress

                # Debug info
                Write-Host "VM Name: $($selectedVM.Name)"
                Write-Host "IP Address: $ipAddress"
                Write-Host "MAC Address: $macAddress"
            } else 
            {
                Write-Host "No network adapter found for VM '$($selectedVM.Name)'." -ForegroundColor Yellow
            }
        }
    } catch 
    {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
function New-Network 
{
    try 
    {
        # Prompt the user for the new network name
        $netName = Read-Host -Prompt "Please Enter the new Network name"

        # Create the switch
        New-VirtualSwitch -Name $netName -VMHost $conf.esxi_host -ErrorAction Stop

        # Create the port group
        New-VirtualPortGroup -Name $netName -VirtualSwitch $netName -ErrorAction Stop

        Write-Host "Network '$netName' created successfully." -ForegroundColor Green
    } catch 
    {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

function Manage_Power
{
    try 
    {
        # Prompt user to select a VM
        $selectedVM = Select-VM -folderName $conf.vm_folder

        if ($selectedVM) {
            # Prompt user to select a power operation
            $powerOperation = Read-Host -Prompt "Enter the power operation (start, stop, restart)"

            # Perform the power operation based on the user input
            switch ($powerOperation) {
                "start" {
                    Start-VM -VM $selectedVM -Confirm:$false
                    Write-Host "VM '$($selectedVM.Name)' started successfully." -ForegroundColor Green
                }
                "stop" {
                    Stop-VM -VM $selectedVM -Confirm:$false
                    Write-Host "VM '$($selectedVM.Name)' stopped successfully." -ForegroundColor Green
                }
                "restart" {
                    Restart-VM -VM $selectedVM -Confirm:$false
                    Write-Host "VM '$($selectedVM.Name)' restarted successfully." -ForegroundColor Green
                }
                default {
                    Write-Host "Invalid power operation. Please enter a valid operation (start, stop, restart)." -ForegroundColor Red
                }
            }
        }
    } catch 
    {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}


function Set-Network 
{
    try 
    {
        # Prompt user to select a VM
        $selectedVM = Select-VM -folderName $conf.vm_folder

        if ($selectedVM) 
        {
            # retrieves the list of available virtual networks
            $virtualNetworks = Get-VirtualNetwork

            # Display the listr of virtual networks to the user
            Write-Host "Available Virtual Networks:" $virtualNetworks | Format-Table -Property Name
            # Prompt user to select a virtual network
            $selectedNetwork = Read-Host -Prompt "Enter the name of the virtual network to set"

            # Check if the selected network exists
            if ($virtualNetworks.Name -contains $selectedNetwork) 
            {
                # Get the network adapter settings of the selected VM
                $networkAdapters = $selectedVM | Get-NetworkAdapter

                # Display the list of network adapters to user
                Write-Host "Available Network Adapters for $($selectedVM.Name):"
                $networkAdapters | Format-Table -Property Name, NetworkName

                # Promept user to select a network adapter
                Write-Host "Select the network adapter by its index:"
                # Loop through network adapters and display them with their index
                for ($i = 0; $i -lt $networkAdapters.Count; $i++) 
                {
                # Display the network adapter name and network name with their index
                    Write-Host "[$($i + 1)] $($networkAdapters[$i].Name) - $($networkAdapters[$i].NetworkName)"
                }
                # Prompts the user to enter the index number of the network adapter to set
                $selectedAdapterIndex = Read-Host -Prompt "Enter the index number of the network adapter to set"

                # Check if the input is a valid number and within the range of available adapters (RegEx string match - used earlier in the script)
                if ($selectedAdapterIndex -match '^\d+$' -and $selectedAdapterIndex -ge 1 -and $selectedAdapterIndex -le $networkAdapters.Count) 
                {
                    # Get the network adapter object based on the selected index
                    $selectedAdapter = $networkAdapters[$selectedAdapterIndex - 1]

                    # Set the network adapter to the selected virtual network
                    Set-NetworkAdapter -NetworkAdapter $selectedAdapter -NetworkName $selectedNetwork
                    Write-Host "Network adapter '$($selectedAdapter.Name)' on VM '$($selectedVM.Name)' set to '$selectedNetwork' successfully." -ForegroundColor Green
                } else 
                {
                    Write-Host "Invalid index. Please enter a valid index between 1 and $($networkAdapters.Count)." -ForegroundColor Red
                }
            } else 
            {
                Write-Host "Virtual network '$selectedNetwork' not found." -ForegroundColor Red
            }
        }
    } catch 
    {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
