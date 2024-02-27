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

Function Select-VM([string] $folder)
{
    $selected_vm=$null
    try 
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        # 480-TODO Need to deal with an invalid index (consider making this check a function)
        $selected_vm = $vms[$pick_index -1]
        Write-Host "You picked " $selected_vm.Name
        # note this is a full on vm object that we can interract with!
        return $selected_vm    
    }
    catch 
    {
        Write-Host "Invalid Folder: $folder" -ForegroundColor Red    <#Do this if a terminating exception happens#>
    }
        
}
