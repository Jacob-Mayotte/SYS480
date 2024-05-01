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
Function Select-Folder {
    try {
        # Retrieves folder names from 480.json file
        $folders = @($conf.vm_folder, $conf.vm2_folder)

        do {
            Write-Host "Available folders:"
            for ($i = 0; $i -lt $folders.Count; $i++) {
                Write-Host "$($i + 1). $($folders[$i])"
            }

            $folderIndex = Read-Host "Enter the index number of the folder you wish to select"
            if ($folderIndex -ge 1 -and $folderIndex -le $folders.Count) {
                return $folders[$folderIndex - 1]
            } else {
                Write-Host "Invalid index. Please enter a valid index between 1 and $($folders.Count)" -ForegroundColor Red
            }
        } while ($true)
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-VM {
    try {
        $selectedFolder = Select-Folder 
        $folder = Get-Folder -Name $selectedFolder
        if ($null -eq $folder) {
            Write-Host "Folder '$selectedFolder' not found. Exiting script." -ForegroundColor Red
            return $null
        }
        $vms = Get-VM -Location $folder
        if ($vms.Count -eq 0) {
            Write-Host "No virtual machines found in folder '$selectedFolder'" -ForegroundColor Yellow
            return $null
        }
        Write-Host "Available VMs in folder '$selectedFolder':"
        $index = 1
        $vms | ForEach-Object {
            Write-Host "$index. $($_.Name)"
            $index++
        }
        do {
            $pick_index = Read-Host "Enter the index number of the VM you wish to select"
            $isValidIndex = $pick_index -ge 1 -and $pick_index -le $vms.Count # Check if the input is a valid number and within the range
            if (-not $isValidIndex) { # Iinput ont valid display an error message
                Write-Host "Invalid index. Please enter a valid index between 1 and $($vms.Count)" -ForegroundColor Red
            }
        } while (-not $isValidIndex)   # Loop until a valid index is selected
        return $vms[$pick_index - 1]  # Return the VM object instead of just its name
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-Datastore() {
    try {
        $datastores = Get-Datastore # gets the datastores from vSphere
        $datastoresCount = $datastores.Count # counts the # of datastores

        # Display the list of datastores with their index
        for ($i = 0; $i -lt $datastoresCount; $i++) { # loops through the datastores and lists them with their index #
            Write-Host ("[" + ($i + 1) + "] " + $datastores[$i].Name) # writes the datastore name & assigning a index #
        }

        while ($true) { # loops until a valid index is selected
            $pick_index = Read-Host "Enter the index number of the datastore you wish to select" # prompts the user to select a datastore

            if ($pick_index -ge 1 -and $pick_index -le $datastoresCount) { # Validates if user input is a valid # and within the range
                $selected_index = [int]$pick_index - 1 # assigns the selected index to a variable
                Write-Host "You picked datastore: $($datastores[$selected_index].Name)"
                return $datastores[$selected_index]
            } else {
                Write-Host "Invalid index. Please enter a valid index."
            }
        }
    } catch { # failsafe for errors
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function Select-Snapshot() { 
    $snapshot_selected = $null

    try {
        $snapshots = Get-VM | ForEach-Object { Get-Snapshot -VM $_ } # gets the snapshots for each VM
        # Display the list of snapshots with their index
        for ($i = 0; $i -lt $snapshots.Count; $i++) { 
            $snapshot = $snapshots[$i] # assigns the snapshot to a variable
            Write-Host ("[" + ($i + 1) + "] " + $snapshot.Name + " - VM: " + $snapshot.VM.Name) # writes the snapshot name, VM name, and assigns a index #
        }
        while ($true) {
            # Prompt user to enter the index number of the snapshot
            $pick_index = Read-Host "Enter the index number of the snapshot you wish to select"

            # Convert user input to integer
            $pick_index = [int]$pick_index

            # Validate if the input is a valid number and within the range of available indices 
            if ($pick_index -ge 1 -and $pick_index -le $snapshots.Count) {
                $snapshot_selected = $snapshots[$pick_index - 1]
                Write-Host "You picked snapshot: $($snapshot_selected.Name) - VM: $($snapshot_selected.VM.Name)"
                return $snapshot_selected 
            } else {
                Write-Host "Invalid index. Please enter a valid index."
            }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $null
    }
}

function New_Clone {
    try {
        # Select VM, snapshot, and datastore
        $selected_vm = Select-VM
        $selected_snapshot = Select-Snapshot
        $selected_datastore = Select-Datastore

        if (-not $selected_snapshot) {
            Write-Host "Snapshot not found for VM $($selected_vm.Name). Exiting script."
            return
        }
        # Prompt user for the new linked clone name
        $cloneName = Read-Host "Enter the new linked clone name"
        $linkedCloneName = "$cloneName.linked"

        # Create the linked clone
        $linkedVM = New-VM -LinkedClone -Name $linkedCloneName -VM $selected_vm -ReferenceSnapshot $selected_snapshot -VMHost $conf.esxi_host -Datastore $selected_datastore

            Write-Host "Linked clone created successfully: $linkedCloneName"
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

        # Create a new base VM from the linked clone
        $baseCloneName = Read-Host "Enter the new base clone name"
        $newVM = New-VM -VM $linkedVM -Name $baseCloneName -VMHost $conf.esxi_host -Location $conf.vm_folder -RunAsync 
        $newVM | Wait-Task

        Write-Host "New base VM '$baseCloneName' created successfully."

            # Remove the linked clone
            # Remove the linked clone
            Write-Host "Removing linked clone: $($linkedVM.Name)..."
        # Remove the linked clone
            Write-Host "Removing linked clone: $($linkedVM.Name)..."
        $linkedVM | Remove-VM -Confirm:$false 
        Write-Host "Linked clone removed successfully."
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
        # Prompts the user to select a VM
        $selectedVM = Select-VM -folderName $conf.vm_folder

        if ($selectedVM) {
            # Prompt user to select a power operation
            $powerOperation = Read-Host -Prompt "Enter the power operation (start, stop, restart)"

            # Performs the power op based on user input
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
