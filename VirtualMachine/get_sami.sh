#!/bin/bash
# Use this script to quickly audit if a VM has System-assigned Managed Identity (SAMI) enabled
# You can actually get identity info from Resource Graph Explorer query unless you would like to practice Bash shell coding
# Usage: sh get_sami.sh xxxx-xxxxx-xxxxx-xxxx

subscription_id="$1"

# Set context for the target subscription

if ! az account set -s "${subscription_id}"; then
  echo "[!] Failed to set subscription context"
  exit
else
  echo "[+] Succesfully set context for subscription Id ${subscription_id}"
fi

# Get VMs in the given subscription
vm_ids=$(az vm list --query '[]'.id -o tsv)
for vm_id in ${vm_ids}; do
  echo "[+] Start checking vm id: ${vm_id}"
  identity=$(az vm identity show --ids "${vm_id}" --query "type" -o tsv)
  if [ -z "${identity}" ]; then
    echo -e "  \e[32m[+] No SAMI found in: ${vm_id}\e[0m"
  elif [[ "${identity}" == *"SystemAssigned"* ]]; then
    echo -e "   \e[31m[+] Found SAMI in: ${vm_id}\e[0m"
  fi
done