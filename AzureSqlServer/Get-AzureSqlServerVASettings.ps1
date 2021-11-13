<# 
  .SYNOPSIS
    This script is used to retrieve vulnerability assessment setting on Azure SQL Server.
  .DESCRIPTION
    This script is used to retrieve vulnerability assessment setting on Azure SQL Server.
    SQL vulnerability assessment is a service that provides visibility into your security state. 
    SQL vulnerability assessment requires Microsoft Defender for SQL plan to be able to run scans.
  .NOTES
    This script is written with Azure Powershell Az module.

    File Name     : Get-AzureSqlServerVASettings.ps1
    Version       : 1.0.0.0
    Author        : AzSec (https://azsec.azurewebsites.net)
    Prerequisite  : Az
  .EXAMPLE
    Get-AzureSqlServerVulnerabilityAssessmentSettings.ps1 -FileName AzSqlVulAssessment
                                                          -Path C:\Audit
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

class azsqlsrvvaCsv {
  [Object]$SubscriptionId
  [Object]$SubscriptionName
  [Object]$ResourceGroupName
  [Object]$ServerName
  [Object]$VaConfigured
  [Object]$StorageAccountName
  [Object]$StorageAccountContainer
  [Object]$RecurringScansInterval
  [Object]$EmailAdminEnabled
  [Object]$Emails
}

$azsqlsrvvaCsvReport = @()

foreach ($subscription in $subscriptions) {
  Set-AzContext -SubscriptionId $($subscription.Id)
  Write-Host -ForegroundColor Green "[-] Start checking subscription:" $($subscription.Id)
  $sqlServers = Get-AzSqlServer
  foreach ($sqlServer in $sqlServers) {
    $azsqlsrvvaObj = [azsqlsrvvaCsv]::new()
    $azsqlsrvvaObj.SubscriptionId = $subscription.Id
    $azsqlsrvvaObj.SubscriptionName = $subscription.Name
    $setting = Get-AzSqlServerVulnerabilityAssessmentSetting -ServerName $sqlServer.ServerName `
                                                             -ResourceGroupName $sqlServer.ResourceGroupName
    if (!$($setting.StorageAccountName)) {
      $azsqlsrvvaObj.VaConfigured = "No"
    }
    else {
      $azsqlsrvvaObj.VaConfigured = "Yes"
    }
    $azsqlsrvvaObj.ResourceGroupName = $setting.ServerName
    $azsqlsrvvaObj.ServerName = $setting.ResourceGroupName
    $azsqlsrvvaObj.StorageAccountName = $setting.StorageAccountName
    $azsqlsrvvaObj.StorageAccountContainer = $setting.ScanResultsContainerName
    $azsqlsrvvaObj.RecurringScansInterval = $setting.RecurringScansInterval
    $azsqlsrvvaObj.EmailAdminEnabled = $setting.EmailAdmins
    $azsqlsrvvaObj.Emails = $setting.NotificationEmail | Out-String

    $azsqlsrvvaCsvReport += $azsqlsrvvaObj
  }
}

$azsqlsrvvaCsvReport | Export-Csv -Path "$Path\$($FileName)_$($date).csv" -NoTypeInformation -Encoding UTF8
Write-Host -ForegroundColor Green "[-] YOUR REPORT IS IN: " $Path\$($FileName)_$($date).csv