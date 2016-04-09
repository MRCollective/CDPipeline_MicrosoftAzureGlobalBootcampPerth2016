Param (
    [string] [Parameter(Mandatory = $true)] $SubscriptionId,
    [string] [Parameter(Mandatory = $true)] $TenantId,
    [string] [Parameter(Mandatory = $true)] $ClientId,
    [string] [Parameter(Mandatory = $true)] $Password,
    [string] [Parameter(Mandatory = $true)] $Location,
    [string] [Parameter(Mandatory = $true)] $AppName,
    [string] [Parameter(Mandatory = $true)] $AppEnvironment,
    [string] $ResourceGroupName = "$AppName-$AppEnvironment-resources",
    [string] $WebHostingPlan = "$AppName-$AppEnvironment-farm",
    [string] $WebAppVMSize = "Small",
    [string] $WebAppEdition = "Standard"
)

function Get-Parameters() {
    return @{
    }
}

try {
    $ErrorActionPreference = "Stop"
    
    Write-Output "Authenticating to ARM as service principal $ClientId"
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $servicePrincipalCredentials = New-Object System.Management.Automation.PSCredential ($ClientId, $securePassword)
    Login-AzureRmAccount -ServicePrincipal -TenantId $TenantId -Credential $servicePrincipalCredentials | Out-Null
    
    Write-Output "Selecting subscription $SubscriptionId"
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId

    Write-Output "Ensuring resource group $ResourceGroupName exists"
    New-AzureRmResourceGroup -Location $Location -Name $ResourceGroupName -Force | Out-Null
    
    Write-Output "Creating parameters for ARM deployment"
    $Parameters = Get-Parameters;
    $Parameters.GetEnumerator() | Sort-Object Name | ForEach-Object {ForEach-Object {"{0}`t{1}" -f $_.Name,($_.Value -join ", ")} | Write-Verbose }
    
    Write-Output "Deploying to ARM"
    $result = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$PSScriptRoot\azuredeploy.json" -TemplateParameterObject $Parameters -Name ("$AppName-$AppEnvironment-" + (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")) -ErrorAction Continue -Verbose
    Write-Output $result
    if ($result.ProvisioningState -ne "Succeeded") {
        throw "Deployment failed"
    }

} catch {
    $Host.UI.WriteErrorLine($_)
    exit 1
}
