<#
    .SYNOPSIS
        This script is used to extract current Azure Security Center settings in all subscriptions you have access to. 
    .DESCRIPTION
        The script supports cross-supscription audit. Your account should have enough privilege (Read access) to retrieve Microsoft.Security resource provider.
    .NOTES
        This script is written with Azure PowerShell Az module.

        File Name     : Get-AzureSecurityCenterInfo.ps1
        Version       : 1.0.0.0
        Author        : AzSec (https://azsec.azurewebsites.net/)
        Prerequisite  : Az
        Reference     : https://azsec.azurewebsites.net/2019/12/15/audit-azure-security-center-in-your-tenant/
    .EXAMPLE
        Get-AzureSecurityCenterInfo.ps1 -FileName AscAudit -Path C:\Audit
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

$subscriptions = Get-AzSubscription
$date = Get-Date -UFormat "%Y_%m_%d_%H%M%S"

class ascInfoCsv {
    [Object]$SubscriptionId
    [Object]$SubscriptionName
    [Object]$VirtualMachineTier
    [Object]$SqlServersTier
    [Object]$AppServicesTier
    [Object]$StorageAccountsTier
    [Object]$SqlServerVirtualMachinesTier
    [Object]$KubernetersServiceTier
    [Object]$ContainerRegistryTier
    [Object]$KeyVaults
    [Object]$AutoProvisioningEnabled
    [Object]$WorkspaceName
    [Object]$WorkspaceRg
    [Object]$ContactEmail
    [Object]$Phone
    [Object]$AlertNotificationEnabled
    [Object]$AlertToAdminsEnabled
}

$ascInfoCsvReport = @()

foreach ($subscription in $subscriptions){
    Set-AzContext -SubscriptionId $subscription.id
    Write-Host -ForegroundColor Green "[-] Start checking subscription:" $subscription.Name
    $workspaceSetting = Get-AzSecurityWorkspaceSetting
    
    $ascInfoObj = [ascInfoCsv]::new()
    $ascInfoObj.SubscriptionId = $subscription.Id
    $ascInfoObj.SubscriptionName = $subscription.Name
    # Get Information about Pricing Tier for each resource type
    Write-Host -ForegroundColor Yellow "[-] Start getting ASC Pricing tier Information in subscription $($subscription.Name)"
    $ascInfoObj.VirtualMachineTier = (Get-AzSecurityPricing -Name "VirtualMachines").PricingTier
    $ascInfoObj.SqlServersTier = (Get-AzSecurityPricing -Name "SqlServers").PricingTier
    $ascInfoObj.AppServicesTier = (Get-AzSecurityPricing -Name "AppServices").PricingTier
    $ascInfoObj.StorageAccountsTier = (Get-AzSecurityPricing -Name "StorageAccounts").PricingTier
    $ascInfoObj.SqlServerVirtualMachinesTier = (Get-AzSecurityPricing -Name "SqlServerVirtualMachines").PricingTier
    $ascInfoObj.KubernetersServiceTier = (Get-AzSecurityPricing -Name "KubernetesService").PricingTier
    $ascInfoObj.ContainerRegistryTier = (Get-AzSecurityPricing -Name "ContainerRegistry").PricingTier
    $ascInfoObj.KeyVaults = (Get-AzSecurityPricing -Name "KeyVaults").PricingTier
    Write-Host -ForegroundColor Yellow "[-] Finished getting ASC Pricing tier Information in subscription $($subscription.Name)"


    # Get Information about Auto Provisioning Setting 
    Write-Host -ForegroundColor Yellow "[-] Start getting ASC Auto Provisioning Setting in subscription $($subscription.Name)"
    $ascInfoObj.AutoProvisioningEnabled = (Get-AzSecurityAutoProvisioningSetting).AutoProvision
    Write-Host -ForegroundColor Yellow "[-] Finished getting ASC Auto Provisioning Setting in subscription $($subscription.Name)"

    # Get Data Collection Workspace Setting
    Write-Host -ForegroundColor Yellow "[-] Start getting ASC Data Collection Workspace Setting in subscription $($subscription.Name)"
    $workspaceId = $workspaceSetting.WorkspaceId
    if (!$workspaceId) {
        $ascInfoObj.WorkspaceName = "Default ASC Workspace"
        $ascInfoObj.WorkspaceRg = "N/A"
    }
    elseif ($workspaceId) {
        $ascInfoObj.WorkspaceName = $workspaceId.Split('/')[8]
        $ascInfoObj.WorkspaceRg = $workspaceId.Split('/')[4]
    }
    Write-Host -ForegroundColor Yellow "[-] Finished getting ASC Data Collection Workspace Setting in subscription $($subscription.Name)"

    # Get Contact and Notification setting
    Write-Host -ForegroundColor Yellow "[-] Start getting ASC Contact and Notification Setting in subscription $($subscription.Name)"
    $ascInfoObj.ContactEmail = (Get-AzSecurityContact).Email | Out-String
    $ascInfoObj.Phone = (Get-AzSecurityContact).Phone | Out-String
    $ascInfoObj.AlertNotificationEnabled = (Get-AzSecurityContact).AlertNotifications
    $ascInfoObj.AlertToAdminsEnabled = (Get-AzSecurityContact).AlertsToAdmins
    Write-Host -ForegroundColor Yellow "[-] Finished getting ASC Contact and Notification Setting in subscription $($subscription.Name)"

    $ascInfoCsvReport += $ascInfoObj
}

$ascInfoCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
Write-Host -ForegroundColor Green "[-] YOUR AZURE SECURITY CENTER REPORT IS IN: " $Path\$($FileName)_$($date).csv
