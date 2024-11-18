terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "iac"
    storage_account_name = "fomojisterraform"
    container_name       = "tfstate"
    key                  = "${var.base_name}-terraform.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
}

variable "base_name" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.base_name
  location = "East US"
}