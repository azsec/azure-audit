<#
    .SYNOPSIS
        This script is used to extract common information in Azure App Service resources that support security and compliance audit. 
    .DESCRIPTION
        The script supports cross-supscription audit. Your account should have enough privilege (Read access) to retrieve Microsoft.Web resource provider.
    .NOTES
        This script is written with AzureRM PowerShell module that shall be deprecated soon. You are advised to upgrade to Azure PowerShell Az module.

        File Name     : Get-AzureAppServiceInfo.ps1
        Version       : 1.0.0.0
        Author        : AzSec (https://azsec.azurewebsites.net/)
        Prerequisite  : AzureRm
    .EXAMPLE
        Get-AzureAppServiceInfo.ps1 -FileName AzureAppAudit -Path C:\Audit
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

class webAppCsv {
    [Object]${SubscriptionId}
    [Object]${SubscriptionName}
    [Object]${WebAppName}
    [Object]${ResourceGroupName}
    [Object]${Location}
    [Object]${State}
    [Object]${HttpsOnly}
    [Object]${AppServicePlan}
    [Object]${Tier}
    [Object]${Size}
    [Object]${minTlsVersion}
    [Object]${ftpsState}
    [Object]${netFrameworkVersion}
    [Object]${phpVersion}
    [Object]${pythonVersion}
    [Object]${nodeVersion}
}

$webAppCsvReport = @()

foreach ($subscription in $subscriptions)
{
    Set-AzureRmContext -SubscriptionId $subscription.id
    Write-Host -ForegroundColor Green "[!] Start checking subscription:" $subscription.Name
    $webApps = Get-AzureRmWebApp
    $appServicePlans = Get-AzureRmAppServicePlan
    foreach($webApp in $webApps){
        #Get app service plan for each web app
        $appServicePlan = $appServicePlans | Where-Object {$_.Id -eq $webApp.ServerFarmId}

        # Get site config of each web app resource
        $config = Get-AzureRmResource -ResourceGroupName $webApp.ResourceGroup `
                                      -ResourceType "Microsoft.Web/sites/config" `
                                      -ResourceName "$($webApp.Name)/web" `
                                      -apiVersion 2016-08-01
        
        $webAppObj = [webAppCsv]::new()
        $webAppObj.SubscriptionId = $subscription.Id
        $webAppObj.SubscriptionName = $subscription.Name
        $webAppObj.WebAppName = $webApp.Name
        $webAppObj.Location = $webApp.Location
        $webAppObj.State = $webApp.State

        Write-Host -ForegroundColor Yellow "[!] Found a web app named:" $webApp.Name
        $webAppObj.ResourceGroupName = $webApp.ResourceGroup

        # To verify HttpsOnly - Web app should always be using this option
        $webAppObj.HttpsOnly = $webApp.HttpsOnly

        # Not all tier supports backup and SSL
        $webAppObj.AppServicePlan = $appServicePlan.AppServicePlanName
        $webAppObj.Tier = $appServicePlan.Sku.Tier
        $webAppObj.Size = $appServicePlan.Sku.Size

        # To verify if Tls version is not old (1.0)
        $webAppObj.minTlsVersion = $config.Properties.minTlsVersion

        # To verify if ftpState allows ftps only - as security practice
        $webAppObj.ftpsState = $config.Properties.ftpsState

        # To verify web app uses latest/patched version
        $webAppObj.netFrameworkVersion = $config.Properties.netFrameworkVersion
        $webAppObj.phpVersion = $config.Properties.phpVersion
        $webAppObj.pythonVersion = $config.Properties.pythonVersion
        $webAppObj.nodeVersion = $config.Properties.nodeVersion
        $webAppCsvReport += $webAppObj
    }
}

$webAppCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
