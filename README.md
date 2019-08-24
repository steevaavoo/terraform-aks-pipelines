[![Build Status](https://dev.azure.com/stevembaker/terraform-aks-yaml-pipelines/_apis/build/status/steevaavoo.terraform-aks-pipelines?branchName=develop)](https://dev.azure.com/stevembaker/terraform-aks-yaml-pipelines/_build/latest?definitionId=7&branchName=develop)

# Goals

- [x] Get an Azure K8s Cluster set up using Terraform through Azure Pipelines
- [x] Deploy an App (nginxdemo) through Azure Pipelines
- [x] Prevent changes to notes (and readme.md) from triggering builds
- [x] Change main build agent to Linux
- [x] Add a stage for Terraform tasks to run specifically with Windows agent
- [ ] Deploy the same App using Helm
- [ ] Update an A record with the address of the App (see Adam's example)

## Method

I'll follow this [tutorial](https://www.azuredevopslabs.com/labs/vstsextend/terraform/)
get familiar with the Terraform Pipeline process, then retrofit it to serve my above purposes.

Notes will be kept in a separate file.
