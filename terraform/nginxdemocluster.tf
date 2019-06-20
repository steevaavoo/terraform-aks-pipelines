# Creating backend storage to store Terraform Remote State
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
  name     = "stvRG1"
  location = "East US"
}
resource "azurerm_container_registry" "stvacr" {
  name                = "stvcontReg1"
  resource_group_name = "${azurerm_resource_group.stvrg.name}"
  location            = "${azurerm_resource_group.stvrg.location}"
  admin_enabled       = false
  sku                 = "Basic"
}

resource "azurerm_kubernetes_cluster" "stvaks" {
  name                = "stvaks1"
  location            = "${azurerm_resource_group.stvrg.location}"
  resource_group_name = "${azurerm_resource_group.stvrg.name}"
  dns_prefix          = "stvagent1"

  agent_pool_profile {
    name            = "default"
    count           = 2
    vm_size         = "Standard_D1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }
  service_principal {
    client_id     = "__clientid__"
    client_secret = "__clientsecret__"
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
