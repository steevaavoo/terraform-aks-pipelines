# This will create an Azure resource group, Storage account and Storage container, used to store terraform remote state
#
# When using Windows agent in Azure DevOps, use batch scripting.
# For batch files use the prefix "call" before every azure command.

# Resource Group
echo "STARTED: Creating Resource Group..."
az group create --location $RESOURCE_LOCATION --name $TERRAFORMSTORAGERG
echo "##vso[task.setprogress value=25;]FINISHED: Creating Resource Group."

# Storage Account
echo "STARTED: Creating Storage Account..."
az storage account create --name $TERRAFORMSTORAGEACCOUNT --resource-group $TERRAFORMSTORAGERG ^
--location $RESOURCE_LOCATION --sku Standard_LRS
echo "##vso[task.setprogress value=50;]FINISHED: Creating Storage Account."

# Storage Container
echo "STARTED: Creating Storage Container..."
az storage container create --name $TF_CONTAINER_NAME --account-name $TERRAFORMSTORAGEACCOUNT
echo "##vso[task.setprogress value=75;]FINISHED: Creating Storage Container."

# Get latest supported AKS version and update Azure DevOps Pipeline variable
echo "STARTED: Finding latest supported AKS version..."
latest_aks_version=$(az aks get-versions -l $RESOURCE_LOCATION --query "orchestrators[-1].orchestratorVersion" -o tsv)
echo "Updating Pipeline variable with Latest AKS Version:"
echo $latest_aks_version
echo ##vso[task.setvariable variable=latest_aks_version]%latest_aks_version%
echo "##vso[task.setprogress value=100;]FINISHED: Finding latest supported AKS version."