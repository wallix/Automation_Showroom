terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.98.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.4"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}