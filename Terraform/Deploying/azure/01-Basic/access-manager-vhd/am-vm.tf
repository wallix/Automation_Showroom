provider "azurerm" {
  features {}
}

provider "cloudinit" {
}

# Use a given resource group
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "template_file" "cloudinit_am" {
  template = file("${path.module}/cloud-init-conf-am.yaml")

  vars = {
    wabadmin_password   = var.wabadmin_password
    wabsuper_password   = var.wabsuper_password
    wabupgrade_password = var.wabupgrade_password
  }

}

data "cloudinit_config" "cloudinit_am" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "cloud-init-conf-am.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloudinit_am.rendered
  }
}

# Retrieve data about an existing subnet
data "azurerm_subnet" "lab-subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

# Uncoment for public ip usage

#Create a public IP -  Uncoment for public ip usage
/*
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-public_ip"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}


output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
  depends_on = [
    azurerm_network_interface.nic
  ]
}

*/
# Create network interface
resource "azurerm_network_interface" "nic" {
  depends_on = [
    # azurerm_public_ip.public_ip # Uncoment for public ip usage
  ]
  name                = "${var.vm_name}-nic"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.lab-subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.public_ip.id # Uncoment for public ip usage
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm-am" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  vm_size             = var.vm_size

  # This line setup to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # This line setup to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  storage_os_disk {
    name          = "${var.vm_name}-osdisk"
    create_option = "FromImage"
    os_type       = "Linux"
    image_uri     = "https://${var.storage_account_name}.blob.core.windows.net/vhds/access-manager-${var.am_version}-azure.vhd"
    vhd_uri       = "https://${var.storage_account_name}.blob.core.windows.net/vhds/osdisk-${var.vm_name}.vhd"
  }


  os_profile {
    computer_name  = var.vm_name
    admin_username = "wabadmin"
    admin_password = var.wabadmin_password
    custom_data    = data.cloudinit_config.cloudinit_am.rendered
  }
  os_profile_linux_config {
    ssh_keys {
      path     = "/home/wabadmin/.ssh/authorized_keys"
      key_data = var.ssh_key
    }
    disable_password_authentication = false
  }

}

# Add auto-shutdown schedule
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto-shutdown-am" {
  virtual_machine_id = azurerm_virtual_machine.vm-am.id
  location           = data.azurerm_resource_group.resource_group.location
  enabled            = true

  daily_recurrence_time = "2100"
  timezone              = "Central Europe Standard Time"
  notification_settings {
    enabled = false
  }
}

