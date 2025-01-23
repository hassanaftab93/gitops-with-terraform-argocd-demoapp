data "azurerm_resource_group" "existing" {
  name = "CloudRnD"
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = "k8s-cluster"
  resource_group_name = data.azurerm_resource_group.existing.name
}