<#
    .SYNOPSIS
        This script is used to extract Azure VM information that support security and compliance audit.
    .DESCRIPTION
        This script supports cross-subscription audit. Your accunt should have enough privilege (Read access) to retrieve Microsoft.Compute resource provider.
    .NOTES
        This script is written with AzureRm PowerShell module that shall be deprecated soon. You are advised to upgrade to Azure PowerShell (Az) module.

        File Name     : Get-AzureVmInfo.ps1
        Version       : 1.0.0.0
        Author        : AzSec (https://azsec.azurewebsites.net/)
        Prerequisite  : AzureRm
    
    .EXAMPLE
        Get-AzureVmInfo -FileName AzureVmAudit -Path C:\Audit
#>

Param(
    [Parameter(Mandatory = $true,
              HelpMessage = "File name of the audit report",
              Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FileName,

    [Parameter(Mandatory = $true,
              HelpMessage = "Location where the audit report is stored",
              Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
)

$subscriptions = Get-AzureRmSubscription
$date = Get-Date -UFormat "%Y_%m_%d_%H%M%S"

class VmCsv {
    [Object]${SubscriptionId}
    [Object]${SubscriptionName}
    [Object]${VmName}
    [Object]${ResourceGroupName}
    [Object]${Location}
    [Object]${PrivateIp}
    [Object]${HostName}
    [Object]${Os}
    [Object]${OsDetail}
}

$vmCsvReport = @()

foreach ($subscription in $subscriptions) {
    Set-AzureRmContext -SubscriptionId $subscription.id
    Write-Host -ForegroundColor Green "[!] Start checking subscription:" $subscription.Name
    $vms = Get-AzureRmVm
    $nics = Get-AzureRmNetworkInterface | Where-Object {$null -ne $_.VirtualMachine}
    foreach ($nic in $nics) {
        $vmObj = [vmCsv]::new()
        $vm = $vms | Where-Object { $_.id -eq $nic.VirtualMachine.id }
        $vmObj.SubscriptionId = $subscription.Id
        $vmObj.SubscriptionName = $subscription.Name
        $vmObj.VmName = $vm.Name
        Write-Host -ForegroundColor Yellow "`t Found a Virtual Machine named:" $vm.Name
        $vmObj.ResourceGroupName = $vm.ResourceGroupName
        $vmObj.Location = $vm.Location
        $vmObj.PrivateIp = $nic.IpConfigurations.PrivateIpAddress
        $vmObj.HostName = $vm.OSProfile.ComputerName
        
        if($vm.OSProfile.LinuxConfiguration) {
            $vmObj.Os = "Linux"
        }
        elseif ($vm.OSProfile.WindowsConfiguration) {
            $vmObj.Os = "Windows"
        }
        $vmObj.OsDetail = $vm.StorageProfile.ImageReference.Offer + $vm.StorageProfile.ImageReference.Sku

        $vmCsvReport += $vmObj
    }
}

$vmCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
