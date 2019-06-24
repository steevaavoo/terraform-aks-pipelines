# the following script will create an Azure resource group, Storage account and Storage container which will be used to store terraform remote state

call az group create --location eastus --name $(terraformstoragerg)

call az storage account create --name $(terraformstorageaccount) --resource-group $(terraformstoragerg) --location eastus --sku Standard_LRS

call az storage container create --name terraform --account-name $(terraformstorageaccount)

# Possible - useful - locations (revealed by az account list-locations)
<#
    "displayName": "East US",
    "name": "eastus",
    "displayName": "East US 2",
    "name": "eastus2",
    "displayName": "West US",
    "name": "westus",
    "displayName": "North Central US",
    "name": "northcentralus",
    "displayName": "South Central US",
    "name": "southcentralus",
    "displayName": "North Europe",
    "name": "northeurope",
    "displayName": "West Europe",
    "name": "westeurope",
    "displayName": "West Central US",
    "name": "westcentralus",
    "displayName": "West US 2",
    "name": "westus2",
    "displayName": "France Central",
    "name": "francecentral",
    "displayName": "France South",
    "name": "francesouth",
#>