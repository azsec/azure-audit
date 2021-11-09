# This script is used to decode encoded cipher used by Azure VM Agent.
# It works with most Azure VM agent today
Add-Type -AssemblyName "System.Security"
$path = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.12\RuntimeSettings\0.settings"
$runSettingFiles = Get-ChildItem -Path $path -Recurse -Filter "*.settings"
foreach ($runSettingFile in $runSettingFiles) {
    $content = Get-Content -Path $runSettingFile.FullName | ConvertFrom-Json
    $certLocation = Set-Location -Path Cert:\LocalMachine\My
    $certs = Get-ChildItem -Path $certLocation | Where-Object {$_.Thumbprint -eq ($($content.runtimeSettings.handlerSettings.protectedSettingsCertThumbprint))}
    foreach ($cert in $certs) {
        Write-Host $cert.Thumbprint
        Write-Host -ForegroundColor Green "Found: " $cert.Subject "that has thumbprint: " $cert.thumbprint:
        $cipher = $content.runtimeSettings.handlerSettings.protectedSettings
        $encryptedBytes = [Convert]::FromBase64String($cipher)
        $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms
        $env.Decode($encryptedBytes)
        $env.Decrypt()
        $clearText = [System.Text.Encoding]::UTF8.GetString($env.ContentInfo.Content)
        $clearText | Convertfrom-Json | Select-Object commandToExecute
    }
} 
