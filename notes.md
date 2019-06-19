# Terraform, AKS and Azure Pipelines

## Part 1 - The Tutorial

### Exercise 1: Azure DevOps Demo Generator & the Terraform file

1. Log in to the [Azure DevOps Demo Generator](https://azuredevopsdemogenerator.azurewebsites.net/environment/createproject)
and set up the details of my project. I went with "terraform-pipeline-tutorial".

    "Terraform" template was pre-selected. I just had to tick the License Terms box to allow the extension to be
    installed/enabled, then click "Create Project"

    One progress bar later, the "PartsUnlimited" repo has been imported.

2. Click "Navigate to project", then click Repos, and switch to the "terraform" branch to check out the "Terraform"
   file (IaC).

3. Navigate to the webapp.tf file in the Terraform folder.

    In here, we can see a bunch of key/value pairs, including a few placeholders (prefixed and suffixed with "__"
    which will be find/replaced later in the Build process.). 

    Webapp.tf is a Terraform config file - Terraform uses its own proprietary Config file format - Hashicorp
    Configuration Language (HCL) which is very similar to YAML (yay!).

    In this particular file, we are specifying an Azure Resource Group. Then an App service plan and an App service - 
    which are required to deploy the website.

### Exercise 2: Build Application using Azure CI* Pipeline

*Continuous Integration - [more info](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-continuous-integration)

1. Go to **Pipelines -> Pipelines**. Select **Terraform-CI** then click **Edit**.

2. You should see a Pipeline heading with several .NET Core steps underneath (Restore, Build, Test, Publish),
followed by 2 steps for processing of "artifacts".

    At a high-level, what these steps seem to be doing is as follows:
    - RESTORE: Restoring Dependencies (presumably similar to the ci command in a Dockerfile)
    - BUILD: Constructing the Configuration file(?)
    - TEST: Adding the Tests to the Configuration file(?)
    - PUBLISH: Creating a Build file as a Zip and adding it to the "Artifact Staging Directory"
    - Copy Terraform files to artifacts: Copies the Terraform files to a "Terraform" subfolder of the "Artifact
      Staging Directory" - this makes them available in the CD (Continuous Delivery) pipeline.
    - Publish Artifact: Publishing the Build Artifacts found in the "Artifact Staging Directory"

3. Click **Queue**, then **Run** to trigger the build. Wait a while... Click the job name to watch the progress in
an adjacent window.

    When the Build has succeeded, go to the Build Summary, check that an Artifact has been published, then click to
    examine it. Expand the "drop" folder, and check for a **Terraform** folder and **PartsUnlimitedWebsite.zip**.

    I found both. This would appear to be good news.

### Exercise 3: Deploy resources using Terraform (IaC) in Azure CD pipeline

(They make it sound so easy!)

1. Go to **Pipelines -> Releases**. Select **Terraform-CD**, then **Edit Pipeline**.

2. Select the **"Dev"** stage, click the *n* job, *n* tasks link to view the pipeline tasks. This will show you
the build tasks. Some settings in these tasks will need your intervention.

3. Select the **Azure CLI** task, select your subscription from the **Azure subscription** drop-down, then click
**Authorize** - I chose to sign in with GitHub as I linked my accounts before. Wait a few moments for the auth
to go through.

    Looking at the **Inline Script** pane, you'll see that Azure is being instructed to create a Storage container
that will be used to store the Terraform State - this helps when working in a team, as Terraform would otherwise
store the State locally on your computer. [More information on remote state](https://www.terraform.io/docs/state/remote.html).

4. Select **Azure Resource Manager** from the **Azure Connection Type**, then your Azure Subscription from
   "Available Azure Service Connections" in the **Azure PowerShell script to get the storage key** job.

    This script will fetch the backend storage key into a $key variable. Then it will use a "write-host"
    command, which is more than meets the eye here. It's using a Visual Studio Online (`##vso`) command to set
    a variable called "storagekey" during build time, which you can see referenced in the **Variables**
    section, named "storagekey" - it's one which is not predetermined - as you can see the value is initially
    set as "PipelineWillGetThisValueRuntime" - cunning!

5. Look at the **Replace tokens...** task - you'll see that this is looking for all files with a .tf extension in
   all folders (**/*.tf) - then, expanding "Advanced", you can see it's looking for a prefix and suffix of "__".

    If you look at the webapp.tf file itself, you'll see a few values with those pre- and suffixes. These are
going to be replaced with the variable values defined in the release pipeline - click **Variables** at the top
to have a look at them.

Terraform's cycle is: init(ialise) > plan > apply.

- Init: Initialize the Working Directory
- Plan: Check out the specified Desired State, compare to the Current State, and plan changes based around that.
- Apply: Enact the changes specified in the Plan.

As such - we have corresponding tasks in our Pipeline.

6. Select each "Terraform" task in turn, and add Azure Resource Manager and our Available Subscription to the
settings.

The **Terraform init** task will look through all of the *.tf files in the current working directory and automatically
downloads any of the required Providers. In this case it will download the Azure provider as we are deploying Azure
resources. The Terraform Template path shows it pointing to the drop/Terraform directory which contains the Terraform
Artifacts (and Web App) we published earlier.

The **Terraform plan** task creates an execution plan. Comparing DS to CS - this is a "dry run", showing the changes
that will be made. Nothing happens... yet.

The **Terraform apply** task will take the Plan from above and execute it. This is where it all happens. Note that
the "-auto-approve" flag has been set - this is because Terraform normally asks for confirmation before applying the
plan - since we are creating an automated build pipeline here, we don't want that.

In the **Azure App Service Deploy:.....** task add the Azure Subscription from Available Service Connections.

This task will deploy the PartsUnlimited package to the Azure app service provisioned by the Terraform steps.

`$appservicename` is referring to a pre-determined value of `pulterraformwebdea81f95`
in this case.

So, now we can click **Save** at the very top, then click **Create a Release**

It will ask for a version for the Artifact Sources - choose the only one available,
then click **Create**

Follow the status message link, then **view logs**, to watch the build in progress.

After the Job succeeds, head over to the **Azure Portal**, then **App Services**

You'll see **pulterraformwebdea81f95** - click it, then click the URL at the top-right
to see it in action.

Very nice. Not fast, since it's free, but hey!

Now how do I make my own version...?

## Part 2: Deploying an Azure K8s Cluster (AKS) with Terraform

Now to see if I can take the above and modify it to work for my own purposes...

### Setting up the .tf File

I will need a .tf file - which I have copied from Hashicorp [here](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html)
and modified to reflect the way I want my Cluster to be configured (2 nodes, basically).

I've named it "nginxdemocluster.tf", and put it inside a folder named "terraform".

Inside the template there are a couple of "Secrets" under the service_principal section - I will pre- and suffix
these with "__" per the original tutorial and add a "Replace Variables" task to the pipeline.

There are more Variables in the Template, which are used to create backend storage for Terraform *remote state* - I
will give further information on these later in the notes.

``` terraform
  service_principal {
    client_id     = "__clientid__"
    client_secret = "__clientsecret__"
  }
```

### Pipeline Setup

First, I need to create a Terraform Pipeline in my new "terraform-aks-pipelines" project in AzDo.

Judging from the Tutorial, I first need to copy my Terraform files to "build artifacts" to make them available in
the CD pipeline...

1. Having created and named the Project in AzDo. I navigate to **Pipelines -> Pipelines**, then click
**Create Pipeline**

2. I choose **Use the classic editor** under **Where is your code?**

3. Under **Select a source** I choose **GitHub**, leave the default name of "GitHub connection 1", then
**Authorize using OAuth**

4. Next I choose the Repository (terraform-aks-pipelines) and default Branch (Develop) and click **Continue**

5. Choose **Empty job** from the top.

6. Leave **Hosted VS2017** as the Agent pool - this will cost, so tidy up afterwards! I'm also happy with the
suggested Name of "terraform-aks-pipelines-CI" (Continuous Integration)

7. Next to **Agent Job 1**, click the **+**,type "copy" into the Search field and Add the "Copy files" task.

8. I click on the "Copy Files to:" task, then: 
    - Change the **Display name** to "Copy Terraform files to artifacts"
    - Specify the "terraform" folder on my Repo as the **Source Folder**
    - Leave the **Contents** as ** because I want everything (there's only 1 file)
    - Change the **Target folder** to `$(build.artifactstagingdirectory)/Terraform`

9. Click the **Save & queue** drop-down and **Save**

10. Repeat step 7 but search for "publish build" and add **Publish build artifacts** task - nothing needs changing

11. Click **Queue**

12. When that finishes, take a look at Artifacts published, inside the **Drop/Terraform** folder you should find the
nginxdemocluster.tf file.

So we've set up the environment from which Terraform can build the cluster we want. Later I'll add more supporting
files to allow us to deploy the nginxdemo itself to the K8s cluster.

### Setting up the Releases (Build) Pipeline

1. Navigate to **Pipelines -> Releases** and click **New pipeline**

2. Choose **Empty job** at the top

3. Stage name - something descriptive - I'll go with **Dev** - click the X at top-right to close

4. Click **+Add an artifact** button
        - **Source (build pipeline)**: "terraform-aks-pipelines-CI"
        - **Default version**: Specify at the time of release creation
        - The rest should be auto-completed.
        - Click **Add**

5. Click on the ***n* job, *n* task** link to start adding tasks

Per the Tutorial, we are going to use the Azure CLI to create some persistent storage in order to use Terraform's
*remote state* capability - this is so that members of a collaborative team can be assured they are all working
from the same state file without having to re-download it locally every time.

6. Click the **+** symbol at the end of the **Agent job** line, type "Azure CLI" in the search...
        - Click **Add** on the **Azure CLI** result
        - Click to expand the Properties of the Task
        - **Display name**: "Azure CLI to deploy Storage for Terraform Remote"
        - **Azure Subscription**: `your Azure subscription`
        - **Script Location**: Inline script
        - **Inline Script**: as below...

```powershell
# the following script will create an Azure resource group, Storage account and Storage container which will be used to store terraform remote state

call az group create --location westus --name $(terraformstoragerg)

call az storage account create --name $(terraformstorageaccount) --resource-group $(terraformstoragerg) --location westus --sku Standard_LRS

call az storage container create --name terraform --account-name $(terraformstorageaccount)
```

7. Click the **+** symbol again, type "Azure power" in the search...
    - Click **Add** on the **Azure PowerShell** result
    - Click to expand the Properties of the Task
    - **Display name**: "Azure PowerShell script to get Storage Key"
    - **Azure Subscription**: \<your Azure subscription\>
    - **Script Type**: Inline script
    - **Inline Script**: as below...
    - **Azure PowerShell Version**: Latest installed version

```powershell
# Using this script we will fetch the storage key which is required in our Terraform file to authenticate to the backend storage account

$key=(Get-AzureRmStorageAccountKey -ResourceGroupName $(terraformstoragerg) -AccountName $(terraformstorageaccount)).Value[0]

Write-Host "##vso[task.setvariable variable=storagekey]$key"
```

8. Now we need to create a Service Principal to allow RBAC for Terraform to build the K8s Cluster
    - NOTE: We only need to do this once per complete test
    - Log in to Azure CLI using az login
    - Run the following:
    - `az ad sp create-for-rbac --name <ServicePrincipaName> --password <StrongPassword>`
    - Click the **Variables** header at the top of the screen and add the following (click **+ Add**):
    - **Name**: clientid | **Value**: \<__http://__*ServicePrincipalName*\> - note the **http://** is required when
    referring to the SPN
    - **Name**: clientsecret | **Value**: \<YourStrongPassword\>
    - Hopefully you established that the Values are copied/pasted from whatever you specified in the command.
    - We also need to add a Variable to contain the Storage Key we're planning to get, so let's do this now -
    we can see that the Inline Script calls it `storagekey` so...
    - **Name**: storagekey | **Value**: willbefetchedbyscript
    - Since I noticed we don't actually have anything mentioning Terraform Remote in our own .tf file, I copied
    the definition for it from the Tutorial (see below) - which means adding more variables...
    - **Name**: terraformstorageaccount | **Value**: terraformstoragestv22f79 <- there are [requirements](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-storage-account-name-errors)
    for the Storage Account name (this is used by Terraform to add Storage to the Resource Group created by the
    Azure CLI task - see below)
    - **Name**: terraformstoragerg | **Value**: terraformrg <- used by Azure CLI Task during backend storage
    creation - also subject to character limits - see overall [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions)

9. We're done with Variables for now, so click Tasks to return to our Task view

10. Click the **+** symbol again, type "replace tokens" in the search...
    - Click **Add** on the **Replace Tokens** result
    - **Display Name**: "Replace tokens in **/*.tf"
    - Target files: **/*.tf
    - Click to expand **Advanced**
    - **Token prefix**: __
    - **Token suffix**: __
    - NOTE: This means the Token Replace will search for `__clientid__` and `__clientsecret__` given how we've named
    them in the Variables section. It will also search for `__storagekey__` which is used to create the Backend
    to store Terraform Remote state, and `__terraformstorageaccount__` for the storage for tf remote state.
    `__terraformrg__`  is used by the PowerShell CLI Task to create a Resource Group for the backend storage created
    in the Terraform file.

11. Click the **+** symbol again, type "terraform" in the search...
    - Click **Add** on the **Run Terraform** result THREE TIMES
    - First, these values need to be added to ALL THREE Terraform Tasks:
        - **Terraform template path**: $(System.DefaultWorkingDirectory)/**/drop/Terraform
            - This is very generalised - because selecting the file specifically will fail to find the file. **AAW**
        - - [x] **Install Terraform**
        - **Terraform Version**: latest
        - - [x] **Use Azure service principal endpoint**
        - **Azure Connection Type**: Azure Resource Manager
        - **Azure Subscription**: \<your azure subscription\>
    - Now, add/rename the Terraform tasks top-to-bottom, as follows:
        - **Top**
        - **Display name**: Terraform init
        - **Terraform arguments**: init
        - **Middle**
        - **Display name**: Terraform plan
        - **Terraform arguments**: plan
        - **Bottom**
        - **Display name**: Terraform apply -auto-approve
        - **Terraform arguments**: apply -auto-approve
    
12. Click **Save**, add any comments, then **OK**

13. Click **Create release**
    - Next to **\terraform-aks-pipelines-CI** choose the latest version
    - Add a **Release description** if wanted
    - Click **Create**

## Next: Deploying the nginxdemo App to the Cluster
