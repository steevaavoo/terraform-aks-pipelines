# Part 1 - The Tutorial

## Exercise 1: Azure DevOps Demo Generator & the Terraform file

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

## Exercise 2: Build Application using Azure CI* Pipeline

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

# Exercise 3: Deploy resources using Terraform (IaC) in Azure CD pipeline

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

4. Select **Azure Resource Manager** from the **Azure Connection Type**, then your Azure Subscription from "Available Azure Service Connections" in the **Azure PowerShell script to get the storage key** job.

    This script will fetch the backend storage key into a $key variable. Then it will use a "write-host"
    command, which is more than meets the eye here. It's using a Visual Studio Online (`##vso`) command to set a variable called "storagekey" during build time, which you can see referenced in the **Variables**
    section, named "storagekey" - it's one which is not predetermined - as you can see the value is initially
    set as "PipelineWillGetThisValueRuntime" - cunning!

5. Look at the **Replace tokens...** task - you'll see that this is looking for all files with a .tf extension in all folders (**/*.tf) - then, expanding "Advanced", you can see it's looking for a prefix and suffix of "__".

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

## Deploying an Azure K8s Cluster (AKS) with Terraform

Since I want to run an nginxdemo container on Azure K8s, I think this is the place
to start. Once I get the hang of this, it'll be time to apply the first half of
the lessons above to Pipeline the process. I think.


