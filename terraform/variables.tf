variable "container_registry_name" {
  default = "stvcontReg1"
}

variable "aks_dns_prefix" {
  default = "stvagent1"
}

variable "azure_resourcegroup_name" {
  default = "__aksrgname__"
}

variable "location" {
  default = "East US"
}

variable "agent_pool_count" {
  default = 2
}
