<#
  .SYNOPSIS
    This script is used to audit if your Web App is configured with Local Git.
  .DESCRIPTION
    This script is used to audit if your Web App is configured with Local Git.
    This script is used for IR team to respond to this vulnerability reported here https://www.wiz.io/blog/azure-app-service-source-code-leak
  .NOTES
    This script is written with AzureRM PowerShell module that shall be deprecated soon. You are advised to upgrade to Azure PowerShell Az module.

    File Name     : Get-LocalGitConfiguration.ps1
    Version       : 1.0.0.0
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

$subscriptions = Get-AzSubscription
$date = Get-Date -UFormat "%Y_%m_%d_%H%M%S"

class webAppCsv {
  [Object]${SubscriptionId}
  [Object]${SubscriptionName}
  [Object]${WebAppName}
  [Object]${ResourceGroupName}
  [Object]${Runtime}
  [Object]${ScmType}
}

$webAppCsvReport = @()

foreach ($subscription in $subscriptions) {
  Write-Host -ForegroundColor Green "[-] Set context for subscription:" $subscription.name
  $context = Set-AzContext -Subscription $subscription.id
  if ($context) {
    Write-Host -ForegroundColor Green "[-] Start checking Web app in subscription:" $subscription.name
    $webApps = Get-AzWebApp
    foreach ($webApp in $webApps) {
      $config = Get-AzResource -ResourceGroupName $webApp.ResourceGroup `
                               -ResourceType "Microsoft.Web/sites/config" `
                               -ResourceName "$($webApp.Name)/web" `
                               -apiVersion 2021-02-01
      $webAppObj = [webAppCsv]::new()
      $webAppObj.SubscriptionId = $subscription.Id
      $webAppObj.SubscriptionName = $subscription.Name
      $webAppObj.WebAppName = $webApp.Name
      $webAppObj.ResourceGroupName = $webApp.ResourceGroup

      if ($($config.Properties.phpVersion)) {
        $webAppObj.Runtime = "php" + $config.Properties.phpVersion
      }
      elseif ($($config.Properties.pythonVersion)) {
        $webAppObj.Runtime = "python" + $config.Properties.pythonVersion
      }
      elseif ($($config.Properties.nodeVersion)) {
        $webAppObj.Runtime = "node" + $config.Properties.nodeVersion
      }
      elseif ($($config.Properties.javaVersion)) {
        $webAppObj.Runtime = "java" + $config.Properties.javaVersion
      }
      elseif ($($config.Properties.linuxFxVersion)) {
        $webAppObj.Runtime = $config.Properties.linuxFxVersion
      }
      elseif ($($config.Properties.windowsFxVersion)) {
        $webAppObj.Runtime = $config.Properties.windowsFxVersion
      }

      $webAppObj.ScmType = $config.Properties.ScmType
      if ($($config.Properties.ScmType) -eq "LocalGit"){
        Write-Host -ForegroundColor Yellow "[!] Found a vulnerable web app:"
        Write-Host -ForegroundColor Red "`t[!] Subscription Name:" $subscription.Name
        Write-Host -ForegroundColor Red "`t[!] Resource Group Name:" $webApp.ResourceGroup
        Write-Host -ForegroundColor Red "`t[!] Web App Name:" $webApp.Name
      }
      $webAppCsvReport += $webAppObj
    }
  }
  else {
    throw "[!] Subscription id $($subscription.id) could not be found. Please try again!"
  }
}

$webAppCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
Write-Host -ForegroundColor Green "[-] Your Audit report is: " $Path\$($FileName)_$($date).csv