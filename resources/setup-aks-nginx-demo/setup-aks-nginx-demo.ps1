# Build and deploy to Azure Kubernetes Service

# Open https://shell.azure.com/ and choose a PowerShell shell
# Copy/paste commands below

# Vars
# no dashes or spaces allowed in prefix, and MUST be lowercase as some character restrictions for some resources
$uniquePrefix = "steevaavoo"
# Shouldn't need to change anything below
$aksClusterName = "$($uniquePrefix)-aks-cluster01"
$acrName = "$($uniquePrefix)acr01"
$location = "eastus"
$aksResourceGroup = "akspipeline"
$aksNodeCount = 2
$version = $(az aks get-versions -l $location --query 'orchestrators[-1].orchestratorVersion' -o tsv)

# Create a Resource Group
az group create --name $aksResourceGroup --location $location

# Deploy Azure Container Registry (ACR)
az acr create --resource-group $aksResourceGroup --name $acrName --sku Basic

# Create AKS using the latest version available
# AKS cluster name MUST be unique, eg: steevaavoo-aks-cluster01
az aks create --resource-group $aksResourceGroup --name $aksClusterName --node-count $aksNodeCount --kubernetes-version $version --enable-addons monitoring --generate-ssh-keys


# Install kubectl locally (if required)
az aks install-cli

# Get the access credentials for the Kubernetes cluster
# Creds are merged into your current console session, eg:
# Merged "steevaavoo-aks-cluster01" as current context in /home/adam/.kube/config
az aks get-credentials --resource-group $aksResourceGroup --name $aksClusterName

# Show k8s nodes / pods
kubectl get nodes
kubectl get pods


# Deploy yaml
kubectl apply -f nginxdemo.yml

# Monitor deployment
kubectl get service nginxdemo --watch
kubectl describe service nginxdemo


# Access the Kubernetes web dashboard in Azure Kubernetes Service (AKS)
https://docs.microsoft.com/en-us/azure/aks/kubernetes-dashboard

# You may need to create a ClusterRoleBinding to access the Web GUI properly
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

# Start the Kubernetes dashboard
az aks browse --resource-group $aksResourceGroup --name $aksClusterName


<# Cleanup
# TODO: work out how to dynamically build Resource Group names
az group delete --no-wait --yes --name $aksResourceGroup
az group delete --no-wait --yes --name MC_$($aksResourceGroup)_$($aksClusterName)_$($location)
az group delete --no-wait --yes --name DefaultResourceGroup-EUS
az group delete --no-wait --yes --name NetworkWatcherRG
#>