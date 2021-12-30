#!/bin/bash
#
# This script can be used to purge all deleted key vaults.
# Use this script when you are lazy at checking deleted vaults and purging manually.
# Take a precaution when running this script in your production environment.
# From a cybersecurity context, an adversary may try to destruct your cloud environment by purging all key vault he deleted. 
# The purge would make the recovery of security incident become impossible.
# To learn more about Azure Key Vault soft-delete and purge protection https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
# When purge protection is enabled, key vault can only be purged after preset period.

# Get all subscriptions under a logged in context
subscription_ids=$(az account list --all --query "[].id" -o tsv)
for subscription_id in ${subscription_ids}; do
  echo -e "\e[32m[+] Found subscription Id ${subscription_id}\e[0m"
  echo -e "  \e[35m[+] Set Subscription context for subscription Id: ${subscription_id}\e[0m"

  # Set subscription context
  az account set -s ${subscription_id}
  if [ $? -eq 0 ]; then
    echo -e "  \e[32m[+] Set subscription context succesfully\e[0m"

    # Get deleted vaults from the given subscription context
    # This action requires Microsoft.KeyVault/deletedVaults/read
    vault_names=$(az keyvault list-deleted --query "[].name" -o tsv)
    if [[ ${vault_names[@]} ]]; then
      for vault_name in ${vault_names}; do
        echo -e "  \e[32m[+] Found deleted vault named ${vault_name}\e[0m"
        echo -e "  \e[35m[+] Start purging ${vault_name}\e[0m"

        # Purge deleted vault
        # This action requires Microsoft.KeyVault/locations/deletedVaults/purge/action
        az keyvault purge --name ${vault_name}
        if [ $? -eq 0 ]; then
          echo -e "  \e[32m[+] Successfully purged key vault ${vault_name}\e[0m"
        else
          echo -e "  \e[31m[!] Failed to purge key vault ${vault_name}\e[0m"
        fi
      done
    else
      echo "  [-] Could not find any deleted vaults"
    fi
  else
    echo -e "  \e[31m[!] Can't set subscription context\e[0m"
    exit 1
  fi
done