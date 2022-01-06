<# 
  .SYNOPSIS
    This script is used to audit System-assigned Managed Identity (SAMI) and User-Assigned Managed Identity (UAMI) attached on VMs and VMss.
  .DESCRIPTION
    Use this script to quickly check your VM(s) and VMSS(s) to see if SAMI or/and UAMI are attached and their role assignments.
    The audit can help you identify if unnecessary use of SAMI and UAMI that may put themselves at risk 
  .NOTES
    This script is written with Azure Powershell Az module.

    File Name     : Get-VmManagedIdentityRoleAssignment.ps1
    Version       : 1.0.0.0
    Author        : AzSec (https://azsec.azurewebsites.net)
    Prerequisite  : Az
  .EXAMPLE
    Get-VmManagedIdentityRoleAssignment.ps1 -Subscription XXXXXX-XXXXX-XXXXXX-XXXXX
#>

Param(
    [Parameter(Mandatory = $true,
               HelpMessage = "The Id of the subscription you want to audit",
               Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubscriptionId
)

$subscriptionContext = Set-AzContext -SubscriptionId $SubscriptionId
Write-Host -ForegroundColor Green "[+] Setting subscription context"
if ($subscriptionContext) {
  Write-Host -ForegroundColor Green "[+] The subscription id $SubscriptionId is valid"
}
else {
  throw "[!] The subscription ID is not valid. Please try again!"
}

$virtualMachineScaleSets = Get-AzVMss
$virtualMachines = Get-AzVM
$computeObjects = @()
$computeObjects += $virtualMachines
$computeObjects += $virtualMachineScaleSets

foreach ($computeObject in $computeObjects) {
  $vmName = $computeObject.Name
  $vmRgName = $computeObject.ResourceGroupName
  $identity = $computeObject.Identity
  $type = $computeObject.Type
  if ($type -eq "Microsoft.Compute/virtualMachines") {
    Write-Host -ForegroundColor Green "[+] Start checking vm: $vmName (rg: $vmRgName)"
  }
  elseif ($type -eq "Microsoft.Compute/virtualMachineScaleSets") {
    Write-Host -ForegroundColor Green "[+] Start checking vmss: $vmName (rg: $vmRgName)" 
  }
  if ($identity) {
    $samiPrincipalId = $identity.PrincipalId
    # Check if SAMI is attached
    if ($samiPrincipalId) {
      Write-Host -ForegroundColor Yellow "`t[+] Found SAMI enabled on vm: $vmName"
      $samiRoleAssignments = Get-AzRoleAssignment -ObjectId $samiPrincipalId
      if ($samiRoleAssignments) {
        foreach ($samiRoleAssignment in $samiRoleAssignments) {
          Write-Host -ForegroundColor White "`t`t[+] SAMI Role        : $($samiRoleAssignment.RoleDefinitionName)"
          Write-Host -ForegroundColor White "`t`t[+] SAMI Role Scope  : $($samiRoleAssignment.Scope)"
          Write-Host -ForegroundColor Green "`t`t....."
        }
      }
      else {
        Write-Host -ForegroundColor White "`t`t[+] The SAMI doesn't have any role assignment"
      }
    }
    $userIdentities = $identity.UserAssignedIdentities.Values
    # Check if UAMI is attached
    if ($userIdentities) {
      Write-Host -ForegroundColor Yellow "`t[+] Found UAMI attached on vm: $vmName"
      foreach ($userIdentity in $userIdentities) {
        $uamiRoleAssignments = Get-AzRoleAssignment -ObjectId $($userIdentity.PrincipalId)
        if ($uamiRoleAssignments) {
          foreach ($uamiRoleAssignment in $uamiRoleAssignments) {
            Write-Host -ForegroundColor White "`t`t[+] UAMI Principal Id  : $($userIdentity.PrincipalId)"
            Write-Host -ForegroundColor White "`t`t[+] UAMI Role          : $($uamiRoleAssignment.RoleDefinitionName)"
            Write-Host -ForegroundColor White "`t`t[+] UAMI Role Scope    : $($uamiRoleAssignment.Scope)"
            Write-Host -ForegroundColor Green "`t`t....."
          }
        }
        else {
          Write-Host -ForegroundColor White "`t`t[+] The UAMI ($($userIdentity.PrincipalId)) doesn't have any role assignment"
        }
      }
    }
    else {
      Write-Host -BackgroundColor Magenta "`t[+] No UAMI has been found"
    }
  }
  else {
    Write-Host -BackgroundColor Magenta "`t[+] No SAMI has been found enabled"
  }
}


