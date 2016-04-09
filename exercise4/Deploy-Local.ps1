$TenantId = ""
$SubscriptionId = ""
$AppName = ""
$Location = "Australia Southeast"
$AppEnvironment = "test"

$profile = Select-AzureRmProfile -Path "$PSScriptRoot\profile.json"
if (-not $profile.Context) {
    Login-AzureRmAccount -TenantId $TenantId | Out-Null
    Save-AzureRmProfile -Path "$PSScriptRoot\profile.json"
}

. $PSScriptRoot\Deploy.ps1 `
    -AlreadyLoggedIn `
    -TenantId $TenantId `
    -SubscriptionId $SubscriptionId `
    -Location $Location `
    -AppName $AppName `
    -AppEnvironment $AppEnvironment
