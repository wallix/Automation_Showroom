######################################################################################
#   Here you will find the configuration for devices, associated services, domains,  #
#   domain accounts, and device groups. If you need more options, please refer to:   #
#   https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs        #
######################################################################################

### DEVICES ###
# Configure devices
resource "wallix-bastion_device" "Demo_UseCase1_Devices" {
  for_each = local.yaml_inventory.vms_inventory # Iterate through your VM map

  # Device attributes
  device_name = each.value.name # Set the name of each device
  host        = each.value.ip   # Set the IP address of each device
}

### DOMAINS ###
# Configure a global domain
resource "wallix-bastion_domain" "Demo_UseCase1_Domains" {
  domain_name = "Demo"
}

### DOMAIN ACCOUNTS ###
# Configure accounts on global domain
resource "wallix-bastion_domain_account" "Demo_UseCase1_Domain_Accounts" {
  ## Ensure that the services have been created beforehand

  depends_on = [
    wallix-bastion_device_service.Demo_UseCase1_Service_RDP,
    wallix-bastion_device_service.Demo_UseCase1_Service_SSH,
  ]

  # Iterate over all users created earlier
  for_each = wallix-bastion_user.Demo_UseCase1_Users

  domain_id     = wallix-bastion_domain.Demo_UseCase1_Domains.id
  account_name  = each.value.user_name # Set the name of each user
  account_login = each.value.user_name # Set the account login of each user
  resources = [
    # Loop through the inventory of VMs for the current user (converted to lowercase).
    # For each VM, construct a string in the format "vm:service",
    # where "vm" is the VM's name and "service" is the associated service.

    for vm in local.yaml_inventory["${lower(each.key)}_inventory"] :
    "${local.yaml_inventory.vms_inventory[vm].name}:${local.yaml_inventory.vms_inventory[vm].service}" # "vm":"service"
  ]
}

### DOMAIN ACCOUNT CREDENTIALS ###
resource "wallix-bastion_domain_account_credential" "Demo_UseCase1_Domain_Accounts_Credentials_SSH" {
  # Create a SSH key for each domain account & associate it
  for_each    = wallix-bastion_domain_account.Demo_UseCase1_Domain_Accounts
  domain_id   = each.value.domain_id
  account_id  = each.value.id
  type        = "ssh_key"
  private_key = "generate:ED25519"
}

resource "wallix-bastion_domain_account_credential" "Demo_UseCase1_Domain_Accounts_Credentials_Password" {
  # Associate all created password for each domain account
  for_each   = wallix-bastion_domain_account.Demo_UseCase1_Domain_Accounts
  domain_id  = each.value.domain_id
  account_id = each.value.id
  type       = "password"
  password   = random_password.secondary_accounts[each.key].result
}

### SERVICES ###
# Create as many services as there are ports declared in your YAML file

# If service port is 22, assign the SSH service with the correct port
resource "wallix-bastion_device_service" "Demo_UseCase1_Service_SSH" {

  for_each = {
    # Iterate over all VMs, filtering by service port 22
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 22
  }

  global_domains    = [wallix-bastion_domain.Demo_UseCase1_Domains.domain_name]
  device_id         = wallix-bastion_device.Demo_UseCase1_Devices[each.key].id # ID of the associated device
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
resource "wallix-bastion_device_service" "Demo_UseCase1_Service_RDP" {

  # Iterate on all VMs, filtering by Service port: 3389
  for_each = {
    for key, vm in local.yaml_inventory.vms_inventory : key => vm
    if vm.port == 3389
  }

  global_domains    = [wallix-bastion_domain.Demo_UseCase1_Domains.domain_name]
  device_id         = wallix-bastion_device.Demo_UseCase1_Devices[each.key].id # ID of the associated device
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
resource "wallix-bastion_targetgroup" "Demo_UseCase1_Target_Groups" {

  depends_on = [
    wallix-bastion_device.Demo_UseCase1_Devices,
    wallix-bastion_domain_account.Demo_UseCase1_Domain_Accounts
  ]
  for_each = local.yaml_inventory.users_inventory

  group_name = each.value.user_name # Name of the target_group

  # Dynamic block for second for_each in 'session_accounts'
  dynamic "session_accounts" {
    for_each = { for vm in local.yaml_inventory["${lower(each.key)}_inventory"] : vm => local.yaml_inventory["vms_inventory"][vm] }
    content {
      account     = each.value.user_name                                    #Make reference to the first for_each
      domain      = wallix-bastion_domain.Demo_UseCase1_Domains.domain_name #Make reference to the created domain
      domain_type = "global"
      device      = session_accounts.value.name    #Make reference to the second for_each
      service     = session_accounts.value.service #Make reference to the second for_each
    }
  }
}
