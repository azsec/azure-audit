<#
  .SYNOPSIS
    This script is used to audit if your Web App is configured with Local Git.
  .DESCRIPTION
    This script is used to audit if your Web App is configured with Local Git.
    This script is used for IR team to respond to this vulnerability reported here https://www.wiz.io/blog/azure-app-service-source-code-leak
  .NOTES
    This script is written with AzureRM PowerShell module that shall be deprecated soon. You are advised to upgrade to Azure PowerShell Az module.

    File Name     : Get-LocalGitConfiguration.ps1
    Version       : 1.0.0.1
    Author        : AzSec (https://azsec.azurewebsites.net/)

  .EXAMPLE
    .\Get-LocalGitConfiguration.ps1 -FileName webappaudit -Path C:\Workspace
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

$webapps = Search-AzGraph -Query "resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId | where type == 'microsoft.web/sites' | where kind has 'linux' or kind has 'functionapp' | order by subscriptionId"

$date = Get-Date -UFormat "%Y_%m_%d_%H%M%S"

class webAppCsv {
  [Object]${SubscriptionId}
  [Object]${SubscriptionName}
  [Object]${WebAppName}
  [Object]${ResourceGroupName}
  [Object]${ScmType}
}

$webAppCsvReport = @()


$context = $null
foreach ($webApp in $webApps) {

  if ($context -ne $webapp.subscriptionId) {
    Write-Host -ForegroundColor Green "[-] Set context for subscription:" $webapp.SubName
    $context = (Set-AzContext -Subscription $webapp.subscriptionId).Subscription.Id
    Write-Host -ForegroundColor Green "[-] Start checking Web app in subscription:" $webapp.SubName
  }

  $config = Get-AzResource -ResourceGroupName $webapp.properties.resourceGroup `
    -ResourceType "Microsoft.Web/sites/config" `
    -ResourceName $webapp.properties.name `
    -ApiVersion 2021-02-01
  $webAppObj = [webAppCsv]::new()
  $webAppObj.SubscriptionId = $webapp.subscriptionId
  $webAppObj.SubscriptionName = $webapp.SubName
  $webAppObj.WebAppName = $webapp.properties.name
  $webAppObj.ResourceGroupName = $webapp.properties.resourceGroup

  $webAppObj.ScmType = $config.Properties.ScmType
  if ($($config.Properties.ScmType) -eq "LocalGit") {
    Write-Host -ForegroundColor Yellow "[!] Found a vulnerable web app:"
    Write-Host -ForegroundColor Red "`t[!] Subscription Name:" $subscription.SubName
    Write-Host -ForegroundColor Red "`t[!] Resource Group Name:" $webapp.properties.resourceGroup
    Write-Host -ForegroundColor Red "`t[!] Web App Name:" $webapp.properties.name
  }
  $webAppCsvReport += $webAppObj
}

$webAppCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
Write-Host -ForegroundColor Green "[-] Your Audit report is: " $Path\$($FileName)_$($date).csv
