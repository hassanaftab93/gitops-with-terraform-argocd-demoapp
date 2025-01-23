## Table of Contents

## [1. Introduction](#introduction)
- Cloud-Native Technologies Overview
- Terraform, Kubernetes, ArgoCD Integration

## [2. Traditional Infrastructure Challenges](#the-traditional-infrastructure-challenge)
- Manual Management Pitfalls
- Deployment Complexities

## [3. Modern Infrastructure Approach](#enter-the-modern-approach-infrastructure-as-code-and-gitops)
- Infrastructure as Code
- GitOps Principles

## [4. Terraform: Infrastructure Provisioning](#terraform-infrastructure-provisioning-reimagined)
- Cluster Configuration
- Network Setup
- Resource Management

## [5. ArgoCD Configuration](#argocd-initial-setup-and-configuration-guide)
- Initial Setup
- RBAC Configuration
- Login Procedures

## [6. GitOps Workflow](#gitops-workflow)
### Repository Structures
- Application Repository
- GitOps Repository
- Manifest Management

### Implementation Strategies
- Repository Configuration
- ArgoCD CLI Commands
- "App of Apps" Pattern

## [7. GitOps Philosophical Principles](#gitops-the-philosophical-shift)
### Core Concepts
- Declarative Configuration
- Version Control
- Automated Synchronization

### Organizational Benefits
- Infrastructure Team Advantages
- Development Team Improvements
- Operational Efficiency

## [8. Practical Implementation Strategy](#practical-implementation-strategy)
- Infrastructure Definition
- ArgoCD Deployment
- Continuous Integration Workflow

## [9. Conclusion](#conclusion)
- Technology Synergy
- Scalability and Agility

## [10. Recommended Tools And Resources](#recommended-tools-and-resources)
- Infrastructure Tools
- Monitoring Solutions
- Version Control Platforms

## Introduction

In the rapidly evolving landscape of cloud-native technologies, organizations are continuously seeking strategies to streamline infrastructure provisioning, enhance deployment reliability, and improve team collaboration.

The combination of Terraform, Kubernetes, ArgoCD, and GitOps principles offers a powerful solution to these challenges.

## The Traditional Infrastructure Challenge

Traditionally, infrastructure management and application deployments were manual, error-prone processes:
- Inconsistent environments
- Configuration drift
- Limited visibility into changes
- Complex rollback procedures
- Slow and risky deployments


![Traditional Infra Deployments to K8s](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/1f5hjvw4gc901ym606cc.jpeg)

---

## Enter the Modern Approach Infrastructure as Code and GitOps

![ArgoCD deployment methods](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/smopnx4kpm5ic5jn2u1d.jpeg)

### Terraform Infrastructure Provisioning Reimagined

Terraform transforms infrastructure management by:
- Defining infrastructure using declarative configuration files
- Supporting multi-cloud and hybrid cloud deployments
- Enabling consistent, reproducible infrastructure creation
- Providing a clear, version-controlled view of infrastructure state

#### Terraform Kubernetes Cluster Provisioning Example

In a project, where my project structure is as follows:

```bash
├── Makefile
├── README.md
├── plans
│   └── plan.tfplan
├── resources.helm.tf
├── resources.main.tf
├── resources.outputs.tf
├── resources.variables.tf
├── terraform.backend.tf
├── terraform.data.tf
├── terraform.locals.tf
└── terraform.provider.tf
```

In `resources.main.tf`, I define the resources required to spin the kubernetes cluster as seen below:

```hcl
module "network_security_group" {
  source              = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/network_security_group"
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
  source              = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/virtual_network"
  name                = "rndvnet"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = ["10.0.0.0/16"]
  depends_on          = [data.azurerm_resource_group.existing, module.network_security_group.this]
  tags                = merge(var.tags)
}

module "k8ssubnet" {
  source                     = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/subnet"
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
  source                     = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/subnet"
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
  source                    = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/subnet_network_security_group_association"
  subnet_id                 = module.k8ssubnet.subnet_id
  network_security_group_id = module.network_security_group.id
  depends_on                = [data.azurerm_resource_group.existing, module.k8ssubnet.this, module.network_security_group.this]
}

module "container_registry" {
  source                           = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/container_registry"
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
  source                               = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/kubernetes/kubernetes_cluster"
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
  source                           = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/role_assignment"
  principal_id                     = module.kubernetes.kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  skip_service_principal_aad_check = true
}
```

Then in `resources.helm.tf`, I define the resources required to configure the helm charts into the above provisioned cluster

```hcl
module "ingress_nginx" {
  source = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/helm/helm_release"

  chart            = "ingress-nginx"
  name             = "ingress-nginx"
  create_namespace = true
  namespace        = "ingress-nginx"
  values = [
    <<-EOF
    controller:
      service:
        type: LoadBalancer
    EOF
  ]
  repository = "https://kubernetes.github.io/ingress-nginx"
  providers = {
    helm = helm.helmk8s
  }
  depends_on = [data.azurerm_kubernetes_cluster.cluster, module.kubernetes]
}

module "argocd" {
  source = "git::ssh://git@ssh.dev.azure.com/v3/<organizationName>/<projectName>/<repoName>//modules/helm/helm_release"

  chart            = "argo-cd"
  name             = "argocd"
  create_namespace = true
  namespace        = "argocd"
  values = [
    <<-EOF
    server:
      service:
        type: ClusterIP
      configs:
        params:
          "server.insecure": "true"
    admin:
        username: admin
    EOF
  ]
  repository = "https://argoproj.github.io/argo-helm"
  providers = {
    helm = helm.helmk8s
  }
  depends_on = [data.azurerm_kubernetes_cluster.cluster, module.kubernetes]
}
```
---

Next, we need to run a few commands to be able to access argoCD's server / CLI

##### ArgoCD Initial Setup and Configuration Guide

###### 1. Password Reset and Retrieval

####### Command Breakdown
```bash
# Reset the admin secret by clearing existing password data
kubectl patch secret argocd-secret -n argocd -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'

##### Restart ArgoCD server to generate new password
kubectl delete pods -n argocd -l app.kubernetes.io/name=argocd-server

##### Retrieve the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

We will use this password later

####### What This Does
- Clears existing admin password
- Triggers ArgoCD to generate a new password
- Extracts the new password for login

###### 2. RBAC (Role-Based Access Control) Configuration

####### Edit RBAC ConfigMap
```bash
kubectl -n argocd edit configmap argocd-rbac-cm
```

####### RBAC Policy Configuration
```yaml
policy.csv: |
# Grant full admin access to all applications
p, role:admin, applications, *, *, *

# Set default role to admin
policy.default: role:admin
```

####### Policy Explanation
- `p, role:admin, applications, *, *, *`: Provides full access to all applications
- `policy.default: role:admin`: Sets admin as the default role for all users

**NOTE:** In our case, we set role:admin, since there will only be one cluster admin that will have access to the kubernetes and/or argoCD server

###### 3. Restart ArgoCD Server

```bash
# Restart ArgoCD to apply RBAC changes
kubectl -n argocd rollout restart deployment argocd-server
```

###### 4. Login to ArgoCD

Since we don't expose our argocd server as a LoadBalancer, or Ingress, we need to access it using port-forwarding, this ensures further security

```bash
# Forward port to access ArgoCD server locally
kubectl port-forward service/argocd-server -n argocd 8888:443

##### Login using admin credentials
argocd login 127.0.0.1:8888 --username admin --password <retrieved-password>
```

Now you can use argocd CLI as well as, open `localhost:8888` in the browser and ... Voila!

![ArgoCD Login Page](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qj3vn8yskal7u6k0i5rr.png)

###### Important Notes
- **Security Warning**: The default admin role provides full cluster access
- Regularly rotate credentials
- Use strong, unique passwords

---

### GitOps Workflow

ArgoCD bridges the gap between Git repositories and Kubernetes clusters:
- Declarative continuous delivery
- Automatic synchronization of application states
- Easy rollbacks and versioning
- Support for multiple sync strategies

#### ArgoCD Application Configuration

##### Application Repo

This repo contains the application code for the microservices, it can be one repo per microservice or it can be a monorepo that holds all microservice code.

It also contains the Pipelines that build and push the images to the Container Registry

```bash
./project
├── Azure-Pipelines
│   ├── azure-pipelines.yml
│   ├── azure-pipelines2.yml
│   └── azure-pipelines3.yml
├── Docker
│   ├── Dockerfile.1
│   ├── Dockerfile.2
│   ├── Dockerfile.3
│   └── nginx.conf
├── demo-app
│   ├── README.md
│   ├── angular.json
│   ├── package.json
│   ├── public
│   │   └── favicon.ico
│   ├── src
│   │   ├── app
│   │   │   ├── app.component.css
│   │   │   ├── app.component.html
│   │   │   ├── app.component.spec.ts
│   │   │   ├── app.component.ts
│   │   │   ├── app.config.server.ts
│   │   │   ├── app.config.ts
│   │   │   └── app.routes.ts
│   │   ├── index.html
│   │   ├── main.server.ts
│   │   ├── main.ts
│   │   ├── server.ts
│   │   └── styles.css
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   └── tsconfig.spec.json
├── demo-app2
│   ├── README.md
│   ├── angular.json
│   ├── package.json
│   ├── public
│   │   └── favicon.ico
│   ├── src
│   │   ├── app
│   │   │   ├── app.component.css
│   │   │   ├── app.component.html
│   │   │   ├── app.component.spec.ts
│   │   │   ├── app.component.ts
│   │   │   ├── app.config.server.ts
│   │   │   ├── app.config.ts
│   │   │   └── app.routes.ts
│   │   ├── index.html
│   │   ├── main.server.ts
│   │   ├── main.ts
│   │   ├── server.ts
│   │   └── styles.css
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   └── tsconfig.spec.json
└── demo-app3
    ├── README.md
    ├── angular.json
    ├── package.json
    ├── public
    │   └── favicon.ico
    ├── src
    │   ├── app
    │   │   ├── app.component.css
    │   │   ├── app.component.html
    │   │   ├── app.component.spec.ts
    │   │   ├── app.component.ts
    │   │   ├── app.config.server.ts
    │   │   ├── app.config.ts
    │   │   └── app.routes.ts
    │   ├── index.html
    │   ├── main.server.ts
    │   ├── main.ts
    │   ├── server.ts
    │   └── styles.css
    ├── tsconfig.app.json
    ├── tsconfig.json
    └── tsconfig.spec.json
```

Let's setup the Azure Pipelines for all 3 demo apps, so images can be pushed into ACR for later deployment


![Azure DevOps Screenshot](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/evm4s8o8py9i42qf5773.png)



---

##### GitOps Repo

Next, we have the GitOps Repo that will be configured with ArgoCD to be monitored

```bash
./demo-app-manifests
├── manifests
│   ├── argocd
│   │   ├── argocd-application-master
│   │   │   └── masterapp.yaml
│   │   └── argocd-applications
│   │       ├── demo-app-argoapp.yaml
│   │       ├── demo-app2-argoapp.yaml
│   │       └── demo-app3-argoapp.yaml
│   └── main
│       ├── demo-app
│       │   ├── deployment.yaml
│       │   └── service-ingress.yaml
│       ├── demo-app2
│       │   ├── deployment.yaml
│       │   └── service-ingress.yaml
│       └── demo-app3
│           ├── deployment.yaml
│           └── service-ingress.yaml
└── readmes
    ├── README.md
    └── argoCD.md
```

The manifests folder is crucial for managing your Kubernetes deployments and configurations using ArgoCD. Here's a detailed look at its contents:

argocd:

argocd-application-master/masterapp.yaml: 

The main ArgoCD application configuration.

argocd-applications:

Contains multiple ArgoCD application configurations (demo-app-argoapp.yaml, demo-app2-argoapp.yaml, demo-app3-argoapp.yaml), following the "App of Apps" pattern.

This pattern allows you to manage multiple applications under a single ArgoCD application.

main:

demo-app, demo-app2, demo-app3:

Each folder contains Kubernetes manifests for deploying and exposing the respective frontend applications.

deployment.yaml:

Defines the deployment configuration for the application.

service-ingress.yaml:

Configures the service and ingress for the application.

###### Run Important ArgoCLI Commands

Add the Azure DevOps repository to ArgoCD using the SSH URL:

```bash
    argocd repo add git@ssh.dev.azure.com:v3/myteo/Cloud/demo-app-manifests \
    --ssh-private-key-path ~/.ssh/id_azure \
    --upsert
```

Create a new ArgoCD project named demo-app-project:

```bash
    argocd proj create demo-app-project \
    --dest https://kubernetes.default.svc,* \
    --description "demo app project" \
    --src git@ssh.dev.azure.com:v3/myteo/Cloud/demo-app-manifests \
    --upsert
```

Now we simply run:

```bash
    kubectl apply -f ./manifests/argocd/argocd-application-master/masterapp.yaml
```

This deploys the master app to the argocd instance, which will now manage all the argoapps referenced under ./manifests/argocd/argocd-applications

This design is called the "App of Apps" pattern, similar to the master-slave node concept

The master app now handles deployment of any app yamls configured under the argocd-applications directory


![ArgoCD Dashboard showing overview](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9v0d83sfox4eqtrolfbp.png)



---

## GitOps The Philosophical Shift

GitOps represents a paradigm shift in infrastructure and application management:

### Core Principles
1. **Declarative Configuration**: Everything is defined as code
2. **Version Control**: Git becomes the single source of truth
3. **Automated Synchronization**: Continuous reconciliation of desired and actual states
4. **Immutable Infrastructure**: Predictable, reproducible environments

## Benefits of This Approach

### For Infrastructure Teams
- Reduced manual intervention
- Improved consistency
- Enhanced security through controlled changes
- Faster recovery from failures

### For Development Teams
- Self-service deployment model
- Increased visibility
- Simplified collaboration
- Faster time-to-market

### For Organizations
- Lower operational complexity
- Reduced human error
- Better compliance and auditing
- Scalable infrastructure management

## Practical Implementation Strategy

1. **Define Infrastructure with Terraform**
   - Create Kubernetes cluster configurations
   - Set up networking and security groups
   - Configure node pools and cluster settings

2. **Install ArgoCD on Kubernetes**
   - Deploy ArgoCD using Terraform or kubectl
   - Configure repository connections
   - Set up application deployment configurations

3. **Implement GitOps Workflow**
   - Store all configurations in Git repositories
   - Use pull requests for change management
   - Leverage ArgoCD for continuous deployment

## Conclusion

The synergy of Terraform, Kubernetes, ArgoCD, and GitOps principles offers a robust, scalable approach to modern infrastructure and application management. By embracing these technologies, organizations can achieve unprecedented levels of efficiency, reliability, and agility.

## Recommended Tools and Resources
- Terraform
- Kubernetes
- ArgoCD
- Helm
- GitHub/GitLab/Azure DevOps
- Prometheus
- Grafana