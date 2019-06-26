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

I'm using GitHub, so the below will be geared towards connecting an AzDo Project Pipeline to a GitHub repository.

### AzDo Project

1. On the Azure DevOps Projects page, click "+ Create project" at the top-right
1. Give the project a name, description and Visibility as desired
1. Click Create

## Section 3: Setting up the Pipelines

### Build Pipeline

#### Initial Setup

1. Click Pipelines, then Pipelines
1. Click Create Pipeline
1. Click "Use the classic editor" since we're not going to use YAML, but Terraform
1. Under Select a source, choose GitHub
1. Customise the Connection name as you wish
1. Click Authorize using OAuth and perform your GitHub login
1. Choose the repository containing your ./terraform and ./manifest folders
1. Choose your desired default branch for manual and scheduled builds - I chose master because a little later I
plan to enable Continuous Integration, triggering only when Pull Requests are approved into the Master branch.
1. Click Continue
1. On the "Select a template" screen, click "Empty Job" at the top
1. Change (or leave) the Pipeline Name as desired
1. Agent pool = HostedVS2017
1. Click the Get sources line
   1. Enable Tag sources "On success"

#### Copying Files from GitHub

Now to add some Tasks. We need the Terraform file and the Kubernetes Manifest files to be available to the
Release Pipeline - to do this, we must copy them from GitHub and create a "Build Artifact" with them inside.

1. Click "Agent job 1"
1. Change the Display name to "Gather Build Artifacts"
1. Click the "+" at the right-end of the "Gather Build Artifacts" line
1. Type "copy" in the search box, point to the "Copy files" task, then click Add
1. Click the "Copy Files to:" task, and rename to "Copy Terraform file to Artifact Staging"
1. Click the ellipses (...) next to "Source Folder" and choose the terraform folder in the repo
1. Contents should be "**" which means everything including subfolders (if any)
1. In the Target Folder, enter `$(build.artifactstagingdirectory)/Terraform`
1. Right-click the "Copy Terraform file to Artifact Staging" task, and click Clone task(s)
1. Click the second instance of the task, rename it to "Copy Kubernetes Manifests to Artifact Staging"
1. Click the ellipses to change the Source Folder to the manifests folder in the repo

#### Creating Pipeline Artifact(s)

1. Click the + to add a new task
1. Search for "publish build" then click Add on the "Publish build artifacts" task
1. Click the "Publish Artifact: drop" task to confirm you're happy with the defaults:
   1. Path to publish should be: $(Build.ArtifactStagingDirectory)
   1. Artifact name should be "drop"
1. Click the Save & queue drop-down, then click Save
1. Leave the folder as "\" - add a comment if wanted

### Release Pipeline

Now we've created a Build Pipeline which will copy our config files, we need to do something with them - enter the
"Release Pipeline"

#### Linking Release Pipeline to Build Pipeline and enabling CI

1. Under the "Pipelines" section, click "Releases"
1. Click "New pipeline"
1. Click "Empty job"
1. Set the Stage Name to "Deploy Infrastructure"
1. Click the X at top-right to close the Stage Properties slide-in
1. Click the name "New release pipeline" and rename to "NginxDemos Release Pipeline"
1. Click "+ Add" under Artifacts
   1. Project is pre-selected - choose Source (build pipeline): \<your build pipeline name\>
   1. Default version: Latest
   1. Source Alias - leave as default
   1. There is a warning that no version is availabe - this is fine, we haven't run a Build yet
1. Click Add
1. Click the lightning-bolt at the top-right of the Artifact you just added
   1. Switch on the Continuous deployment trigger
   1. Click Add, then choose "Include" and specify "master" Build branch
   1. Click "X" at the top-right to close the slide-in

#### Adding "Deploy Infrastructure" Tasks

##### Creating Storage for Terraform Remote State
[Terraform Remote State explained](https://www.terraform.io/docs/state/remote.html)

1. Click the "Tasks" heading at the top
1. Click the "+" on the Agent job line
1. Search for "azure cli" and Add the Azure CLI Task
1. Click the "Azure CLI" task to customise
   1. Display Name: "Azure CLI - deploy Terraform Remote State storage"
   1. Azure Subscription - choose your Azure Subscription, Authorize as required
   1. Script location: "Inline script" - script follows (paste in):

   ```azurecli
   # the following script will create an Azure resource group, Storage account and Storage container which will be used to store terraform remote state

   call az group create --location eastus --name $(terraformstoragerg)

   call az storage account create --name $(terraformstorageaccount) --resource-group $(terraformstoragerg) --location eastus --sku Standard_LRS

   call az storage container create --name terraform --account-name $(terraformstorageaccount)
   ```

#### Getting Storage Key with PowerShell

1. Click the "Tasks" heading at the top
1. Click the "+" on the Agent job line
1. Search for "azure powershell" and Add the "Azure PowerShell" task
1. Customise as follows:
   1. Display name: "Azure PowerShell script to get Storage Key"
   1. Azure Subscription: choose your Azure subscription (should be listed under "Available")
   1. Script Type: Inline Script - script follows (paste in):
   
   ```azurecli
   # Using this script we will fetch the storage key which is required in our Terraform file to authenticate to the backend storage account

   $key=(Get-AzureRmStorageAccountKey -ResourceGroupName $(terraformstoragerg) -AccountName $(terraformstorageaccount)).Value[0]

   Write-Host "##vso[task.setvariable variable=storagekey]$key"
   ```

   1. Azure PowerShell Version: Latest installed version

#### Setting Variables

For the time being, we're done with the Tasks - since we need to generate and dynamically assign - and obtain -
some variables, such as for the Resource Group name, Storage Key etc. let's define them now.

Click the "Variables" heading at the top, then add the following key/value pairs into "Pipeline Variables".

*NOTE: the next Task we add to the build pipeline will reference some of these to replace the* `"__"` *pre-and suffixed*
*variables in the Terraform file.*
*The others are used by the inline scripts we defined above to name the Terraform Remote State storage group and*
*store the Key.*

| **Name**                | **Value**                          |
| ----------------------- | ---------------------------------- |
| aksclustername          | \<youraksclustername\>             |
| aksrgname               | \<youraksresourcegroupname\>       |
| ClientID                | http://\<your-spn-name\>           |
| ClientSecret            | \<yourstrongpassword\>             |
| k8sapiserverfqdn        | willbefetchedbyscript              |
| storagekey              | willbefetchedbyscript              |
| terraformstorageaccount | \<yourstoragegroupname\>           |
| terraformstoragerg      | \<yourtfstorageresourcegroupname\> |

Make sure to follow the appropriate [naming rules](https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions)
for the variables specifying resource names.

####  Applying Variables to Terraform file

1. Head back to the Tasks section, and click + to add another task
1. Search for "replace tokens" and Add the "Replace Tokens" task (make sure it's bottom of the list)
1. Customise the "Replace Tokens" task as follows:
   1. Display name: 
   1. Target files: `**/*`
   1. Expand "Advanced"
      1. Token prefix: `__`
      1. Token suffix: `__`

This will search for all the variables in the Terraform file which start and end with "__", and will replace them
with the values of the matching keys we defined in the "Variables" tab above.

