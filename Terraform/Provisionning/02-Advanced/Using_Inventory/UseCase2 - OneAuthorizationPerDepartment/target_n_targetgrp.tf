############################################################################################
#   Here you will find the configuration for devices, associated services, local domains,  #
#   domain accounts, and device groups. If you need more options, please refer to:         #
#   https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs              #
############################################################################################

### DEVICES ###
# Configure devices
resource "wallix-bastion_device" "Demo_UseCase2_Devices" {
  for_each = local.yaml_inventory.vms_inventory # Iterate through your VM map

  # Device attributes
  device_name = each.value.name # Set the name of each device
  host        = each.value.ip   # Set the IP address of each device
}

### LOCAL DOMAINS ###
# Configure a local domain
resource "wallix-bastion_device_localdomain" "Demo_UseCase2_Localdomain" {
  for_each    = wallix-bastion_device.Demo_UseCase2_Devices
  device_id   = each.value.id
  domain_name = "local"
}

### LOCAL DOMAIN ACCOUNTS ###
# Configure accounts on local domain
resource "wallix-bastion_device_localdomain_account" "Demo_UseCase2_Localdomain_Accounts" {
  # Ensure that the services have been created beforehand
  depends_on = [
    wallix-bastion_device.Demo_UseCase2_Devices,
  ]

  for_each = local.yaml_inventory.vms_inventory # Iterate through your VM map

  device_id     = wallix-bastion_device.Demo_UseCase2_Devices[each.key].id
  domain_id     = wallix-bastion_device_localdomain.Demo_UseCase2_Localdomain[each.key].id
  account_name  = each.value.account
  account_login = each.value.account
}

### LOCAL DOMAIN ACCOUNT CREDENTIALS ###
resource "wallix-bastion_device_localdomain_account_credential" "Demo_UseCase2_Localdomain_Accounts_Credentials_SSH" {
  # Create a SSH key for each localdomain account & associate it
  for_each = {
    # Iterate over all VMs, filtering by service port 22
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 22
  }
  device_id   = wallix-bastion_device.Demo_UseCase2_Devices[each.key].id
  domain_id   = wallix-bastion_device_localdomain.Demo_UseCase2_Localdomain[each.key].id
  account_id  = wallix-bastion_device_localdomain_account.Demo_UseCase2_Localdomain_Accounts[each.key].id
  type        = "ssh_key"
  private_key = "generate:ED25519"
}

resource "wallix-bastion_device_localdomain_account_credential" "Demo_UseCase2_LocalDomain_Accounts_Credentials_Password" {
  # Associate all created password for each domain account
  for_each = {
    # Iterate over all VMs, filtering by service port 3389
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 3389
  }
  device_id  = wallix-bastion_device.Demo_UseCase2_Devices[each.key].id
  domain_id  = wallix-bastion_device_localdomain.Demo_UseCase2_Localdomain[each.key].id
  account_id = wallix-bastion_device_localdomain_account.Demo_UseCase2_Localdomain_Accounts[each.key].id
  type       = "password"
  password   = random_password.secondary_accounts[each.key].result
}

### SERVICES ###
# Create as many services as there are ports declared in your YAML file

# If service port is 22, assign the SSH service with the correct port
resource "wallix-bastion_device_service" "Demo_UseCase2_Service_SSH" {

  for_each = {
    # Iterate over all VMs, filtering by service port 22
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 22
  }

  device_id         = wallix-bastion_device.Demo_UseCase2_Devices[each.key].id # ID of the associated device
  service_name      = "SSH"                                                    # Name of the service
  connection_policy = "SSH"                                                    # Define SSH as the connection policy
  port              = 22                                                       # SSH port
  protocol          = "SSH"                                                    # Protocol used
  subprotocols = ["SSH_SHELL_SESSION",
    "SSH_SHELL_SESSION",
    "SSH_REMOTE_COMMAND",
    "SSH_SCP_UP",
    "SSH_SCP_DOWN",
    "SFTP_SESSION",
  ]
}
# If service port is 3389 -> assign rdp service with good port
resource "wallix-bastion_device_service" "Demo_UseCase2_Service_RDP" {

  # Iterate on all VMs, filtering by Service port: 3389
  for_each = {
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 3389
  }

  device_id         = wallix-bastion_device.Demo_UseCase2_Devices[each.key].id # ID of the associated device
  service_name      = "RDP"                                                    # Name of the service
  connection_policy = "RDP"                                                    # Define RDP as the connection policy
  port              = 3389                                                     # RDP port
  protocol          = "RDP"                                                    # Protocol used
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
resource "wallix-bastion_targetgroup" "Demo_UseCase2_Target_Groups" {

  depends_on = [
    wallix-bastion_device.Demo_UseCase2_Devices,
    wallix-bastion_device_localdomain_account.Demo_UseCase2_Localdomain_Accounts
  ]

  # Iteration over each group in the target_group_inventory
  for_each = local.yaml_inventory.target_group_inventory

  # Group name is the key (group name) of each iteration in target_group_inventory
  group_name = each.key

  # Dynamic block for iterating over the devices (VMs) for each group
  dynamic "session_accounts" {
    for_each = [
      for vm in each.value : {
        name    = local.yaml_inventory.vms_inventory[vm].name
        account = local.yaml_inventory.vms_inventory[vm].account
        service = local.yaml_inventory.vms_inventory[vm].service
      }
    ]
    content {
      account     = session_accounts.value.account                                                                       # Reference to account of the device
      domain      = wallix-bastion_device_localdomain.Demo_UseCase2_Localdomain[session_accounts.value.name].domain_name # Reference to the created domain
      domain_type = "local"
      device      = session_accounts.value.name    # Reference to the name of the device
      service     = session_accounts.value.service # Reference to the service of the device
    }
  }
}

