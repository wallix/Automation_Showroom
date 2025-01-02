############################################################################################
#   Here you will find the configuration for devices, associated services, local domains,  #
#   domain accounts, and device groups. If you need more options, please refer to:         #
#   https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs              #
############################################################################################

# Create a flattened list of accounts with their corresponding name.
# This list bypasses Terraform's limitations for creating nested "for" loops. 
locals {
  vm_info = flatten([
    for vm_key, vm in local.yaml_inventory.vms_inventory : [
      for account in vm.accounts : {
        name    = vm.name
        ip      = vm.ip
        account = account
        port    = vm.port
        service = vm.service
        url     = vm.url
      }
    ]
  ])
}

### DEVICES ###
# Configure devices
resource "wallix-bastion_device" "Demo_UseCase3_Devices" {
  for_each = local.yaml_inventory.vms_inventory # Iterate through your VM map

  # Device attributes
  device_name = each.value.name # Set the name of each device
  host        = each.value.ip   # Set the IP address of each device
}

### LOCAL DOMAINS ###
# Configure a local domain
resource "wallix-bastion_device_localdomain" "Demo_UseCase3_Localdomain" {
  for_each    = wallix-bastion_device.Demo_UseCase3_Devices
  device_id   = each.value.id
  domain_name = "local"
}

### LOCAL DOMAIN ACCOUNTS ###
# Configure accounts on local domain
resource "wallix-bastion_device_localdomain_account" "Demo_UseCase3_Localdomain_Accounts" {
  # Ensure that the services have been created beforehand
  depends_on = [
    wallix-bastion_device.Demo_UseCase3_Devices,
  ]

  # Iterate on vm_info
  for_each = { for vm_info in local.vm_info : "${vm_info.name}_${vm_info.account}" => {
    name    = vm_info.name
    account = vm_info.account
    }
  }

  device_id     = wallix-bastion_device.Demo_UseCase3_Devices[each.value.name].id
  domain_id     = wallix-bastion_device_localdomain.Demo_UseCase3_Localdomain[each.value.name].id
  account_name  = each.value.account
  account_login = each.value.account
}

### LOCAL DOMAIN ACCOUNT CREDENTIALS ###
resource "wallix-bastion_device_localdomain_account_credential" "Demo_UseCase3_Localdomain_Accounts_Credentials_SSH" {
  # Create a SSH key for each localdomain account & associate it
  for_each = {
    # Iterate over the flattened list and filter by service port 22 within the resource
    for vm_info in local.vm_info :
    "${vm_info.name}_${vm_info.account}" => vm_info
    if vm_info.port == 22
  }
  device_id   = wallix-bastion_device.Demo_UseCase3_Devices[each.value.name].id
  domain_id   = wallix-bastion_device_localdomain.Demo_UseCase3_Localdomain[each.value.name].id
  account_id  = wallix-bastion_device_localdomain_account.Demo_UseCase3_Localdomain_Accounts["${each.value.name}_${each.value.account}"].id
  type        = "ssh_key"
  private_key = "generate:ED25519"
}

resource "wallix-bastion_device_localdomain_account_credential" "Demo_UseCase3_LocalDomain_Accounts_Credentials_Password" {
  # Associate all created password for each domain account
  for_each = {
    # Iterate over the flattened list and filter by service port 3389 within the resource
    for vm_info in local.vm_info : "${vm_info.name}_${vm_info.account}" => vm_info
    if vm_info.port == 3389
  }
  device_id  = wallix-bastion_device.Demo_UseCase3_Devices[each.value.name].id
  domain_id  = wallix-bastion_device_localdomain.Demo_UseCase3_Localdomain[each.value.name].id
  account_id = wallix-bastion_device_localdomain_account.Demo_UseCase3_Localdomain_Accounts["${each.value.name}_${each.value.account}"].id
  type       = "password"
  password   = random_password.secondary_accounts["${each.value.name}-${each.value.account}-password"].result
}

### SERVICES ###
# Create as many services as there are ports declared in your YAML file

# If service port is 22, assign the SSH service with the correct port
resource "wallix-bastion_device_service" "Demo_UseCase3_Service_SSH" {

  for_each = {
    # Iterate over all VMs, filtering by service port 22
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 22
  }

  device_id         = wallix-bastion_device.Demo_UseCase3_Devices[each.value.name].id # ID of the associated device
  service_name      = "SSH"                                                           # Name of the service
  connection_policy = "SSH"                                                           # Define SSH as the connection policy
  port              = 22                                                              # SSH port
  protocol          = "SSH"                                                           # Protocol used
  subprotocols = ["SSH_SHELL_SESSION",
    "SSH_SHELL_SESSION",
    "SSH_REMOTE_COMMAND",
    "SSH_SCP_UP",
    "SSH_SCP_DOWN",
    "SFTP_SESSION",
  ]
}
# If service port is 3389 -> assign rdp service with good port
resource "wallix-bastion_device_service" "Demo_UseCase3_Service_RDP" {

  for_each = {
    # Iterate over all VMs, filtering by service port 3389
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 3389
  }

  device_id         = wallix-bastion_device.Demo_UseCase3_Devices[each.value.name].id # ID of the associated device
  service_name      = "RDP"                                                           # Name of the service
  connection_policy = "RDP"                                                           # Define RDP as the connection policy
  port              = 3389                                                            # RDP port
  protocol          = "RDP"                                                           # Protocol used
  subprotocols = [
    "RDP_CLIPBOARD_UP",
    "RDP_CLIPBOARD_DOWN",
    "RDP_CLIPBOARD_FILE",
    "RDP_PRINTER",
    "RDP_COM_PORT",
    "RDP_DRIVE",
    "RDP_SMARTCARD",
    "RDP_AUDIO_OUTPUT"
  ]
}

### TARGET GROUPS ###
resource "wallix-bastion_targetgroup" "Demo_UseCase3_Target_Groups" {

  depends_on = [
    wallix-bastion_device.Demo_UseCase3_Devices,
    wallix-bastion_device_localdomain_account.Demo_UseCase3_Localdomain_Accounts
  ]

  # Iteration over each entry in vm_info
  for_each = {
    # Iterate over the flattened list
    for vm_info in local.vm_info : "${vm_info.name}_${vm_info.account}" => vm_info
  }

  # Group name is dynamically created using name and account
  group_name = "${each.value.name}_${each.value.account}"

  # Dynamic block for session_accounts
  session_accounts {
    account     = each.value.account                                                                       # Account name
    domain      = wallix-bastion_device_localdomain.Demo_UseCase3_Localdomain[each.value.name].domain_name # Domain name
    domain_type = "local"                                                                                  # Static value
    device      = each.value.name                                                                          # Device name
    service     = each.value.service                                                                       # Service (port) of the device
  }
}
