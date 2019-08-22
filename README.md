# Goals

1. Get an Azure K8s Cluster set up using Terraform through Azure Pipelines
1. Deploy an App (nginxdemo) through Azure Pipelines
1. Prevent changes to notes (and readme.md) from triggering builds
1. Change all build agents to Linux
1. Deploy the same App using Helm
1. Update an A record with the address of the App (see Adam's example)

## Method

I'll follow this [tutorial](https://www.azuredevopslabs.com/labs/vstsextend/terraform/)
get familiar with the Terraform Pipeline process, then retrofit it to serve my above purposes.

Notes will be kept in a separate file and will follow my rather random way of thinking, so
please forgive any meandering nonsense...

Adding this line to test exclusion of .MD files from Build Triggers.
