terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id # null: read from ARM_SUBSCRIPTION_ID
}

locals {
  public_access = length(var.allowed_ips) > 0
  location      = data.azurerm_resource_group.resource_group.location
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_subnet" "lab-subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_storage_account" "vhds" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

data "cloudinit_config" "cloudinit_am" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-conf-am.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init-conf-am.yaml", {
      wabadmin_password   = var.wabadmin_password
      wabsuper_password   = var.wabsuper_password
      wabupgrade_password = var.wabupgrade_password
    })
  }
}

# Managed image built from the WALLIX VHD (unmanaged OS disks are retired on Azure).
resource "azurerm_image" "am" {
  name                = "${var.vm_name}-image"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  os_disk {
    os_type      = "Linux"
    os_state     = "Generalized"
    blob_uri     = "${data.azurerm_storage_account.vhds.primary_blob_endpoint}vhds/access-manager-${var.am_version}-azure.vhd"
    caching      = "ReadWrite"
    storage_type = var.os_disk_type
  }
}

resource "azurerm_public_ip" "public_ip" {
  count               = local.public_access ? 1 : 0
  name                = "${var.vm_name}-public-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  count               = local.public_access ? 1 : 0
  name                = "${var.vm_name}-nsg"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "wallix-am-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "2242"]
    source_address_prefixes    = var.allowed_ips
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.lab-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.public_ip[0].id, null)
  }
}

resource "azurerm_network_interface_security_group_association" "nsg" {
  count                     = local.public_access ? 1 : 0
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_linux_virtual_machine" "vm-am" {
  name                  = var.vm_name
  resource_group_name   = data.azurerm_resource_group.resource_group.name
  location              = local.location
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.nic.id]
  source_image_id       = azurerm_image.am.id

  computer_name                   = var.vm_name
  admin_username                  = "wabadmin"
  admin_password                  = var.wabadmin_password
  disable_password_authentication = false
  custom_data                     = data.cloudinit_config.cloudinit_am.rendered

  admin_ssh_key {
    username   = "wabadmin"
    public_key = var.ssh_key
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }
}

# Lab cost control: stops (deallocates) the VM every day at 21:00.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto-shutdown-am" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm-am.id
  location           = local.location
  enabled            = true

  daily_recurrence_time = "2100"
  timezone              = "Central Europe Standard Time"

  notification_settings {
    enabled = false
  }
}
