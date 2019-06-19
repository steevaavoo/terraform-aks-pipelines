resource "azurerm_resource_group" "steevaavoo" {
  name     = "steevaavooRG1"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "steevaavoo" {
  name                = "steevaavooaks1"
  location            = "${azurerm_resource_group.steevaavoo.location}"
  resource_group_name = "${azurerm_resource_group.steevaavoo.name}"
  dns_prefix          = "steevaavooagent1"

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
  value = "${azurerm_kubernetes_cluster.steevaavoo.kube_config.0.client_certificate}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.steevaavoo.kube_config_raw}"
}
