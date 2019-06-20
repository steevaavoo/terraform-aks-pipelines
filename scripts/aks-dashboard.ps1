# Get the access credentials for the Kubernetes cluster
# Creds are merged into your current console session, eg:
# Merged "steevaavoo-aks-cluster01" as current context in /home/adam/.kube/config
az aks get-credentials --resource-group stvRG1 --name stvaks1

# Show k8s nodes / pods
kubectl get nodes
kubectl get pods

# Access the Kubernetes web dashboard in Azure Kubernetes Service (AKS)
https://docs.microsoft.com/en-us/azure/aks/kubernetes-dashboard

# Start the Kubernetes dashboard
az aks browse --resource-group stvRG1 --name stvaks1
