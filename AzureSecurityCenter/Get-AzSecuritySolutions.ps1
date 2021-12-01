<#
    .SYNOPSIS
        This script is used to get all security solutions deployed in Microsoft Defender for Cloud.
    .DESCRIPTION
        This script is used to get all security solutions deployed in Microsoft Defender for Cloud.
    .NOTES
        This script is written with Azure PowerShell Az module.

        File Name     : Get-AzSecuritySolutions.ps1
        Version       : 1.0.0.0
        Author        : AzSec (https://azsec.azurewebsites.net/)
        Prerequisite  : Az.Accounts
                        Az.Security
    .EXAMPLE
        Get-AzSecuritySolutions.ps1 -SubscriptionId "XXXXX-XXXXXXXX-XXXXXXX"
#>
Param(
    [Parameter(Mandatory = $true,
               HelpMessage = "The Id of the subscription you want to get all security solutions on",
               Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubscriptionId
)

$subscriptionContext = Set-AzContext -SubscriptionId $SubscriptionId
if ($subscriptionContext) {
  Write-Host -ForegroundColor Green "[+] The subscription id $SubscriptionId is valid"
}
else {
  throw "[!] The subscription ID is not valid. Please try again!"
}

# This is an unofficial API. Use at your own risk.
$apiVersion = "2015-06-01-preview"

$accessToken = Get-AzAccessToken -ResourceTypeName "ResourceManager"
$authHeader = @{
  'Content-Type'  = 'application/json'
  'Authorization' = 'Bearer ' + $accessToken.Token
}

$locations = (Get-AzSecurityLocation).Name
if ($locations) {
  foreach ($location in $locations) {
    Write-Host -ForegroundColor Green "`t[+] Found location: $location"
    Write-Host -ForegroundColor Green "`t[+] Start retrieving security solutions"
    $uri = "https://management.azure.com/subscriptions/" + $SubscriptionId `
                                                         + "/providers/Microsoft.Security/locations/" `
                                                         + $location `
                                                         + "/securitySolutions" `
                                                         + "?api-version=" `
                                                         + $apiVersion
    $response = Invoke-RestMethod -Uri $uri `
                                  -Method GET `
                                  -Headers $authHeader
    if (-not ([string]::IsNullOrEmpty($response))) {
      Write-Host -ForegroundColor Green "`t[+] Found solution template: " $response.value.properties.template
      Write-Host -ForegroundColor Green "`t[+] Below is configuration detail: " 
      $response.value.properties
    }
  }
}
