$globalTag = @{
    "Project" = "AzSec"
    "Year" = "2022"
    "Cloud" = "Azure"
}

# Only get active subscriptions
$subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled" }
foreach ($subscription in $subscriptions) {
    Write-Host -ForegroundColor Green "[+] Found subscription named: " $subscription.Name
    Write-Host -ForegroundColor Green "`t[+] Start applying tag for subscription named: " $subscription.Name
    $tag = New-AzTag -ResourceId "/subscriptions/$($subscription.id)" -Tag $globalTag
    if ($tag) {
        Write-Host -ForegroundColor Green "`t[+] Succesfully applied tag for subscription named: " $subscription.Name
    }
    else {
        Write-Host -ForegroundColor Red "`t[!] Failed to applied tag for subscription named: " $subscription.Name
    }
}