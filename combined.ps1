function Get-ClusterCapacityCheck {

    [CmdletBinding()]
    param(
    [Parameter(Position=0,Mandatory=$true,HelpMessage="Name of the cluster to test",
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
    [System.String]
    $ClusterName
    )
    
    begin {
    #$Finish = (Get-Date -Hour 0 -Minute 0 -Second 0)
    #$Start = $Finish.AddDays(-1).AddSeconds(1)
    
    New-VIProperty -Name FreeSpaceGB -ObjectType Datastore -Value {
    param($ds)
    [Math]::Round($ds.FreeSpaceMb/1KB,0)
    } -Force
    
    }
    
    process {
    
    $Cluster = Get-Cluster $ClusterName
    
    #$ClusterCPUCores = $Cluster.ExtensionData.Summary.NumCpuCores
    #$ClusterEffectiveMemoryGB = [math]::round(($Cluster.ExtensionData.Summary.EffectiveMemory / 1KB),0)
    
    $ClusterVMs = $Cluster | Get-VM
    
    #$ClusterAllocatedvCPUs = ($ClusterVMs | Measure-Object -Property NumCPu -Sum).Sum
    #$ClusterAllocatedMemoryGB = [math]::round(($ClusterVMs | Measure-Object -Property MemoryMB -Sum).Sum / 1KB)
    
    #$ClustervCPUpCPURatio = [math]::round($ClusterAllocatedvCPUs / $ClusterCPUCores,2)
    #$ClusterActiveMemoryPercentage = [math]::round(($Cluster | Get-Stat -Stat mem.usage.average -Start $Start -Finish $Finish | Measure-Object -Property Value -Average).Average,0)
    
    $VMHost = $Cluster | Get-VMHost | Select-Object -Last 1
    $ClusterFreeDiskspaceGB = ($VMHost | Get-Datastore | Where-Object {$_.Extensiondata.Summary.MultipleHostAccess -eq $True} | Measure-Object -Property FreeSpaceGB -Sum).Sum
    $ClusterCPUUsageMHz = ($VMHost | Measure-Object -Property CpuUsageMhz -Sum).Sum
    $ClusterCPUTotalMHz = ($VMHost | Measure-Object -Property CpuTotalMhz -Sum).Sum
    $ClusterNumCPU = ($VMHost | Measure-Object -Property NumCpu -Sum).Sum
    $ClusterTotalMemory = ($VMHost | Measure-Object -Property MemoryTotalGB -Sum).Sum
    $ClusterUsedMemory = ($VMHost | Measure-Object -Property MemoryUsageGB -Sum).Sum
    
    $ClusterFreeCPUGHz = Round(($ClusterCPUTotalMHz - $ClusterCPUUsageMHz)/1000,2)
    $ClusterFreeCPUGHz_PerCore = Round(($ClusterFreeCPUGHz/ ($ClusterCPUTotalMHz/(1000*$ClusterNumCPU))),2)
    $ClusterMemory = $ClusterTotalMemory - $ClusterUsedMemory

    New-Object -TypeName PSObject -Property @{
    Cluster = $Cluster.Name
    #ClusterCPUCores = $ClusterCPUCores
    #ClusterAllocatedvCPUs = $ClusterAllocatedvCPUs
    #ClustervCPUpCPURatio = $ClustervCPUpCPURatio
    #ClusterEffectiveMemoryGB = $ClusterEffectiveMemoryGB
    #ClusterAllocatedMemoryGB = $ClusterAllocatedMemoryGB
    #ClusterActiveMemoryPercentage = $ClusterActiveMemoryPercentage
    ClusterFreeDiskspaceGB = $ClusterFreeDiskspaceGB
    ClusterCPUUsageMHz = $ClusterCPUUsageMHz
    ClusterCPUTotalMHz = $ClusterCPUTotalMHz
    ClusterFreeCPUGHz = $ClusterFreeCPUGHz
    ClusterFreeCPUGHz_PerCore = $ClusterFreeCPUGHz_PerCore
    ClusterMemory = $ClusterMemory

    }
    }
    }
    #Get-Cluster | Get-ClusterCapacityCheck | Select-Object Cluster,ClusterCPUCores,ClusterAllocatedvCPUs,ClustervCPUpCPURatio,ClusterEffectiveMemoryGB,ClusterAllocatedMemoryGB,ClusterActiveMemoryPercentage,ClusterFreeDiskspaceGB
    Get-Cluster | Get-ClusterCapacityCheck | Select-Object Cluster,ClusterFreeDiskspaceGB,ClusterCPUUsageMHz,ClusterCPUTotalMHz,ClusterFreeCPUGHz,ClusterFreeCPUGHz_PerCore,ClusterMemory
    


    @{N='Used CPU(GHz)';E={[math]::Round($_.CpuUsageMhz/1000,2)}},
    @{N='Free CPU(GHz)';E={[math]::Round(($_.CpuTotalMhz - $_.CpuUsageMhz)/1000,2)}},
    @{N='Free CPU(/Core)';E={[math]::Round(((($_.CpuTotalMhz - $_.CpuUsageMhz)/1000)/($_.CpuTotalMhz/(1000*$_.NumCpu))),0)}},
    @{N='Total Memory(GB)';E={[math]::Round($_.MemoryTotalGB,2)}},
    #@{N='Memory Used GB';E={[math]::Round($_.MemoryUsageGB,2)}},
    @{N='Free Memory(GB)';E={[math]::Round(($_.MemoryTotalGB - $_.MemoryUsageGB),0)}} |
    Export-Csv -Path C:\Materials\Downloads\capacityfinalreport-master\report.csv -NoTypeInformation -UseCulture
    
    