terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "iac"
    storage_account_name = "fomojisterraform"
    container_name       = "tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

############ AKS Cluster ############

resource "random_pet" "aks_cluster_name" {
  prefix = "cluster"
}

resource "random_pet" "aks_cluster_dns_prefix" {
  prefix = "dns"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = random_pet.aks_cluster_name.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.aks_cluster_dns_prefix.id
  oidc_issuer_enabled = true

  network_profile {
    network_plugin = "azure"
  }

  ingress_application_gateway {
    gateway_name = "appgw"
    subnet_cidr  = "10.225.0.0/16"
  }

  default_node_pool {
    name       = "default"
    node_count = var.nodes
    vm_size    = "Standard_D2ps_v6"
  }

  identity {
    type = "SystemAssigned"
  }
}

############ Azure Container Registry ############

resource "random_string" "acr_name" {
  length  = 5
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_container_registry" "acr" {
  name                = "${random_string.acr_name.result}registry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

resource "azurerm_role_assignment" "acr_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

############ Passwords ############

resource "random_password" "mainnet-rpc-password" {
  length  = 32
  special = false
}

resource "random_password" "testnet-rpc-password" {
  length  = 32
  special = false
}

############ Load Balancer ############

resource "azurerm_user_assigned_identity" "alb-identity" {
  location            = azurerm_resource_group.rg.location
  name                = "alb-identity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "alb-role" {
  principal_id                     = azurerm_user_assigned_identity.alb-identity.principal_id
  role_definition_name             = "Reader"
  scope                            = azurerm_kubernetes_cluster.aks.node_resource_group_id
  skip_service_principal_aad_check = true
}

resource "azurerm_federated_identity_credential" "alb-identity" {
  name                = "azure-alb-identity"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.alb-identity.id
  subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
}

# resource "azurerm_role_assignment" "agic-addon-identity" {
#   principal_id                     = 
#   role_definition_name             = "Network Contributor"
#   scope                            = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].subnet_cidr
#   skip_service_principal_aad_check = true
# }