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

  default_node_pool {
    name       = "default"
    node_count = 2
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
  length = 32
}

resource "random_password" "testnet-rpc-password" {
  length = 32
}