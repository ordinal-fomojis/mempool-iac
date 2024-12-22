terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "iac"
    storage_account_name = "fomojisterraform"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = var.location
  resource_group_name = var.rg_name

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v5"
  }

  identity {
    type = "SystemAssigned"
  }
}