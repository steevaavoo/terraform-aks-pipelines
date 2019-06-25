# Deploying an App on a Kubernetes Cluster in AKS built with Terraform through Azure Pipelines

How I created an AKS cluster with Terraform through Azure Pipelines, then successfully and repeatably deployed the
nginxdemos/hello Containerised App.

## Section 1: Gathering Resources

### Terraform File

In order to define an AKS cluster using Terraform, I went in search of an appropriate example file to customise for
my purposes - which led me to [this example](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html).

I downloaded the file and saved it to a ./terraform folder in my Repo. Then changed a few options (see repo for
example) such as the resource group names, number of nodes, as well as substituting a few static values with variable
names prefixed and suffixed with "__" - because I would need to set and access these dynamically within the Build 
pipeline, later in the process. The replacements were:

```hcl
__aksrgname__
__aksclustername__
```

```hcl
  service_principal {
    client_id     = "__clientid__"
    client_secret = "__clientsecret__"
  }
```

As always for my labs, I set the Locations universally to East US as these are the cheapest (at time of writing).

### Kubernetes YAML Files

I needed to create a couple of YAML files to feed to the Kubernetes Cluster API Server to create a Deployment and 
a Service - both of which are present in the ./manifests folder of my repo, and define a simple 10 Pod Deployment
of the nginxdemos/hello Container with a Load Balancer Service listening on Port 80 - which, from looking at the
[nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) repository on Docker Hub, we know is configured to
listen on Port 80.

### Nginx Demos "Hello"

Since this is hosted on Docker Hub, we needn't worry about getting the files ourselves, we can rely on the Kubernetes
Container Engine to go fetch it when we Deploy.

Later, however, we will use the Azure Container Registry that we create within the .tf file to build the App using
Docker, which will allow us to customise the listener port - just as an example.

## Section 2: Environment Setup

### AzDo Project


