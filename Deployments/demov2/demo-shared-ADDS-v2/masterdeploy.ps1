# Resourcegroups deployments
# Make sure to have Owner priviledge level in Azure to deploy the Resource Groups as locking requires Owner's level access. To increase level go to:
# https://portal.azure.com/#blade/Microsoft_Azure_PIM/CrossProviderActivationMenuBlade/azureResourceRoles/isAADGroupVisible//isAADRbacVisible/

Param(
    [string]$TemplateParameterFile = "",
    [string]$storageRG = "Demo-Infra-Storage-RG",
    [string]$storageAccountName = "deployments",
    [string]$containerName = "demo-shared-adds-v2",
    [string]$location = "canadacentral"
)

$ErrorActionPreference = "Stop"

# sign in
#Write-Host "Logging in...";
if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) {
    Write-Host "You need to login. Minimize the Visual Studio Code and login to the window that poped-up"
    Login-AzureRmAccount
}

Write-Host "Copying parameters files for deployment to https://$deploymentStorageAccountName.blob.core.windows.net/$containerName"

& (Resolve-Path -Path "$PSScriptRoot\scripts\upload-parameters-files.ps1") -containerName $containerName

Write-Host "Starting base infrastructure deployment..."

# Get storageaccount name that contains parameters files
$deploymentStorageAccountName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $storageRG -Name "storageAccount.$storageAccountName").Outputs.storageAccountName.value

$null = Set-AzureRmCurrentStorageAccount -ResourceGroupName $storageRG -Name $deploymentStorageAccountName

# Create the SaS token for the contrainer
$token = New-AzureStorageContainerSASToken -Name $containerName -Permission r -ExpiryTime (Get-Date).AddMinutes(90.0)

# Deploy base infrastructure
New-AzureRmDeployment -Location $Location -Name $containerName -TemplateUri "https://azpwsdeployment.blob.core.windows.net/library/arm/masterdeploy/20190319.1/masterdeployrg.json" -TemplateParameterFile (Resolve-Path -Path "$PSScriptRoot\parameters\masterdeployrg-shared-ADDS.parameters.json") -baseParametersURL "https://$deploymentStorageAccountName.blob.core.windows.net/$containerName/" -parametersSasToken $token -Verbose;

Write-Host "There was no deployment errors detected. All look good."