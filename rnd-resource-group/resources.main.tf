module "network_security_group" {
  source              = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/network_security_group"
  name                = "rnd-nsg"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  rules = [
    {
      name                       = "nsg-rule-1"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "nsg-rule-2"
      priority                   = 101
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  depends_on = [data.azurerm_resource_group.existing]
  tags       = merge(var.tags)
}

module "virtual_network" {
  source              = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/virtual_network"
  name                = "rndvnet"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = ["10.0.0.0/16"]
  depends_on          = [data.azurerm_resource_group.existing, module.network_security_group.this]
  tags                = merge(var.tags)
}

module "k8ssubnet" {
  source                     = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/subnet"
  name                       = "rndsubnetk8s"
  resource_group_name        = data.azurerm_resource_group.existing.name
  virtual_network_name       = module.virtual_network.virtual_network_name
  subnet_address_prefix      = ["10.0.1.0/24"]
  service_endpoints          = ["Microsoft.Storage", "Microsoft.Web"]
  delegation_name            = null
  service_delegation_name    = null
  service_delegation_actions = null
  depends_on                 = [data.azurerm_resource_group.existing, module.virtual_network.this, module.network_security_group.this]
}

module "podsubnet" {
  source                     = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/subnet"
  name                       = "rndsubnetpods"
  resource_group_name        = data.azurerm_resource_group.existing.name
  virtual_network_name       = module.virtual_network.virtual_network_name
  subnet_address_prefix      = ["10.0.2.0/24"]
  service_endpoints          = ["Microsoft.Storage"]
  delegation_name            = "aks-delegation"
  service_delegation_name    = "Microsoft.ContainerService/managedClusters"
  service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  depends_on                 = [data.azurerm_resource_group.existing, module.virtual_network.this, module.network_security_group.this]
}

module "subnet_nsg_association" {
  source                    = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/subnet_network_security_group_association"
  subnet_id                 = module.k8ssubnet.subnet_id
  network_security_group_id = module.network_security_group.id
  depends_on                = [data.azurerm_resource_group.existing, module.k8ssubnet.this, module.network_security_group.this]
}

module "container_registry" {
  source                           = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/container_registry"
  resource_group_name              = data.azurerm_resource_group.existing.name
  location                         = data.azurerm_resource_group.existing.location
  name                             = "rndacrteo"
  sku                              = "Standard"
  is_admin_enabled                 = true
  is_public_network_access_enabled = true
  depends_on                       = [data.azurerm_resource_group.existing]
  tags                             = merge(var.tags)
}

module "kubernetes" {
  source                               = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/kubernetes/kubernetes_cluster"
  name                                 = "k8s-cluster"
  resource_group_name                  = data.azurerm_resource_group.existing.name
  location                             = data.azurerm_resource_group.existing.location
  node_count                           = 1
  dns_prefix                           = "rndaks"
  vnet_subnet_id                       = module.k8ssubnet.subnet_id
  vm_size                              = "Standard_A2_v2"
  pod_subnet_id                        = module.podsubnet.subnet_id
  kubernetes_version                   = "1.30.0"
  is_role_based_access_control_enabled = true
  sku_tier                             = "Free"
  default_node_pool_name               = "k8spool"
  service_cidr                         = "10.1.0.0/16"
  dns_service_ip                       = "10.1.0.10"
  depends_on                           = [module.k8ssubnet.this, module.podsubnet.this]
}

module "k8s_role_assignment" {
  source                           = "git::ssh://git@ssh.dev.azure.com/v3/myteo/Cloud/Terraform-Modules//modules/role_assignment"
  principal_id                     = module.kubernetes.kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  skip_service_principal_aad_check = true
}