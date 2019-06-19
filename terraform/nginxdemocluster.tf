resource "steevaavoo_resource_group" "test" {
  name     = "acctestRG1"
  location = "East US"
}

resource "steevaavoo_kubernetes_cluster" "test" {
  name                = "acctestaks1"
  location            = "${steevaavoo_resource_group.test.location}"
  resource_group_name = "${steevaavoo_resource_group.test.name}"
  dns_prefix          = "acctestagent1"

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
  value = "${steevaavoo_kubernetes_cluster.test.kube_config.0.client_certificate}"
}

output "kube_config" {
  value = "${steevaavoo_kubernetes_cluster.test.kube_config_raw}"
}