#!/bin/bash
# This script is written for lazy people who want to stop or start all VMs at once.
# Use this script when you build a large lab but don't want to stop/start each VM.
# Auto shutdown is a helpful built-in feature but you don't know when you need to stop all VMs.

subscription_id="$1"
action="$2"

# Set context for the target subscription

if ! az account set -s "${subscription_id}"; then
  echo "[!] Failed to set subscription context"
  exit
else
  echo "[+] Succesfully set context for subscription Id ${subscription_id}"
fi

# Get VMs in the given subscription
vm_ids=$(az vm list --query '[]'.id -o tsv)
for vm_id in "${vm_ids[@]}"; do
  if [ "${action}" == "start" ]; then
    echo "[+] Your action is: ${action}"
    stop_vm_ids=$(az vm get-instance-view --ids "${vm_id}" --query "[?instanceView.statuses[1].code!='PowerState/running']".id -o tsv)
    for stop_vm_id in "${stop_vm_ids[@]}"; do
      echo "[+] Start vm id: ${stop_vm_id}"
      az vm start --ids "${stop_vm_id}" --no-wait
    done
  elif [ "${action}" == "stop" ]; then
    running_vm_ids=$(az vm get-instance-view --ids "${vm_id}" --query "[?instanceView.statuses[1].code=='PowerState/running']".id -o tsv)
    for running_vm_id in "${running_vm_ids[@]}"; do
      echo "[+] Stop vm id: ${running_vm_id}"
      az vm stop --ids "${running_vm_id}" --no-wait
    done
  else
    echo "[!] Action accepts Stop or Start value. Please try again!"
  fi
done