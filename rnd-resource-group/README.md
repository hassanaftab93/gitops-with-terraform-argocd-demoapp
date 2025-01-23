# Terraform Module Testing

This repository contains Terraform modules for testing various Azure resources. The modules are designed to be reusable and configurable, allowing you to easily deploy and manage Azure infrastructure.

## Modules

### Kubernetes Cluster

This module deploys an Azure Kubernetes Service (AKS) cluster with configurable parameters.

#### Inputs

- `name`: The name of the Kubernetes cluster.
- `location`: The location/region where the Kubernetes cluster will be deployed.
- `resource_group_name`: The name of the resource group.
- `dns_prefix`: The DNS prefix for the Kubernetes cluster.
- `kubernetes_version`: The version of Kubernetes to deploy.
- `is_role_based_access_control_enabled`: Whether role-based access control is enabled.
- `sku_tier`: The SKU tier for the Kubernetes cluster.
- `default_node_pool_name`: The name of the default node pool.
- `is_auto_scaling_enabled`: Whether auto-scaling is enabled for the node pool.
- `node_count`: The initial number of nodes in the node pool.
- `max_count`: The maximum number of nodes in the node pool.
- `min_count`: The minimum number of nodes in the node pool.
- `vm_size`: The size of the virtual machines in the node pool.
- `pod_subnet_id`: The subnet ID for the pods.
- `vnet_subnet_id`: The subnet ID for the virtual network.
- `tags`: A map of tags to assign to the resources.

#### Outputs

- `client_certificate`: The client certificate from the Kubernetes cluster's kube config.
- `kube_config`: The raw kube config for the Kubernetes cluster.
- `id`: The ID of the Kubernetes cluster.
- `current_kubernetes_version`: The current Kubernetes version of the cluster.
- `fqdn`: The fully qualified domain name of the cluster.

### Container Apps

This module deploys Azure Container Apps with configurable parameters.

#### Inputs

- `container_apps`: A list of container app configurations.
- `container_app_environment_id`: The ID of the container app environment.
- `resource_group_name`: The name of the resource group.
- `revision_mode`: The revision mode for the container apps.
- `container_registry_server`: The server for the container registry.
- `container_registry_username`: The username for the container registry.
- `is_latest_version`: Whether the latest version is used.
- `tags`: A map of tags to assign to the resources.

#### Outputs

- `container_app_ids`: A list of IDs for the deployed container apps.

## Usage

To use these modules, include them in your Terraform configuration and provide the necessary input variables. For example:

```hcl
module "kubernetes_cluster" {
  source = "./modules/kubernetes_cluster"
  name = "my-aks-cluster"
  location = "East US"
  resource_group_name = "my-resource-group"
  dns_prefix = "myaks"
  kubernetes_version = "1.21.2"
  is_role_based_access_control_enabled = true
  sku_tier = "Standard"
  default_node_pool_name = "default"
  is_auto_scaling_enabled = true
  node_count = 3
  max_count = 5
  min_count = 1
  vm_size = "Standard_DS2_v2"
  pod_subnet_id = "subnet-id"
  vnet_subnet_id = "vnet-subnet-id"
  tags = {
    environment = "testing"
  }
}

module "container_app" {
  source = "./modules/container_app"
  container_apps = var.container_apps
  container_app_environment_id = var.container_app_environment_id
  resource_group_name = var.resource_group_name
  revision_mode = var.revision_mode
  container_registry_server = var.container_registry_server
  container_registry_username = var.container_registry_username
  is_latest_version = var.is_latest_version
  tags = var.tags
}
```