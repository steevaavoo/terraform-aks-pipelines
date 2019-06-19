# Build and deploy to Azure Kubernetes Service
# https://docs.microsoft.com/en-us/azure/devops/pipelines/languages/aks-template?view=azure-devops

# Open https://shell.azure.com/ and choose a BASH shell
# Copy/paste commands below

# Vars
# no dashes or spaces allowed in prefix, and MUST be lowercase as some character restrictions for some resources
UNIQUE_PREFIX="steevaavoo"
# Shouldn't need to change anything below
AKS_CLUSTER_NAME="${UNIQUE_PREFIX}-aks-cluster01"
# My docker images (templates) will be uploaded to this private area (Azure Container Registry)
ACR_NAME="${UNIQUE_PREFIX}acr01"
# Logical container in Azure for collections of resources
AKS_RESOURCE_GROUP="akspipeline"
# The cheap location ;)
LOCATION="eastus"

# Create a Resource Group
az group create --name $AKS_RESOURCE_GROUP --location $LOCATION

# Deploy Azure Container Registry (ACR)
az acr create --resource-group $AKS_RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Create AKS using the latest version available
# AKS cluster name MUST be unique, eg: steevaavoo-aks-cluster01
az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --enable-addons monitoring --generate-ssh-keys --node-count 1


# Cleanup
# Use PowerShell:
# Get-AzResourceGroup | Remove-AzResourceGroup -AsJob -Force
# Get-Job | Wait-Job