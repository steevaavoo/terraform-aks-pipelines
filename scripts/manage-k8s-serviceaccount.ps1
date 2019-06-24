kubectl config view -o jsonpath="{.clusters.stvaks1.cluster.server}"

$kubeconfig = kubectl config view -o json | ConvertFrom-Json

$kubeconfig.clusters.cluster.server

$kubeconfig

#

# Creating the Service Account
kubectl create sa stvsa

# Getting the Service Account in YAML format
$serviceaccountyml = kubectl get serviceaccounts stvsa -o yaml

# Getting the ServiceAccount in JSON to extract the unique Secret Name:
$serviceaccountsjson = kubectl get serviceaccounts stvsa -o json | ConvertFrom-Json
$serviceaccountsecretname = $serviceaccountsjson.secrets.name

# Getting the ServiceAccountSecretName in YAML from $serviceaccountsecretname
kubectl get secret $serviceaccountsecretname -o yaml

#BINGPOT

# How to reference a pipeline variable: $(VARIABLENAME)