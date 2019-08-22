# Deploying Terraform Remote State to AZ Storage Container - Variables not allowed here.
terraform {
  required_version = ">= 0.11"
  backend "azurerm" {
    storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
    access_key           = "__storagekey__"
  }
}
resource "azurerm_resource_group" "stvrg" {
  name     = "${var.azure_resourcegroup_name}"
  location = "${var.location}"
}
resource "azurerm_container_registry" "stvacr" {
  name                = "${var.container_registry_name}"
  resource_group_name = "${azurerm_resource_group.stvrg.name}"
  location            = "${azurerm_resource_group.stvrg.location}"
  admin_enabled       = "${var.acr_admin_enabled}"
  sku                 = "${var.acr_sku}"
}

resource "azurerm_kubernetes_cluster" "stvaks" {
  name                = "${var.azurerm_kubernetes_cluster_name}"
  location            = "${azurerm_resource_group.stvrg.location}"
  resource_group_name = "${azurerm_resource_group.stvrg.name}"
  dns_prefix          = "${var.aks_dns_prefix}"

  agent_pool_profile {
    name            = "${var.agent_pool_profile_name}"
    count           = "${var.agent_pool_count}"
    vm_size         = "${var.agent_pool_profile_vm_size}"
    os_type         = "${var.agent_pool_profile_os_type}"
    os_disk_size_gb = "${var.agent_pool_profile_disk_size_gb}"
  }
  service_principal {
    client_id     = "${var.service_principal_client_id}"
    client_secret = "${var.service_principal_client_secret}"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value = "${azurerm_kubernetes_cluster.stvaks.kube_config.0.client_certificate}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.stvaks.kube_config_raw}"
}
