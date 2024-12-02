# Configure a device
resource "wallix-bastion_device" "demo" {
  device_name = "server1"
  host        = "server1"
}

# Configure a global domain
resource "wallix-bastion_domain" "demo" {
  domain_name = "globdomexample.com"
}

# Configure an account on global domain
resource "wallix-bastion_domain_account" "demo" {
  domain_id     = wallix-bastion_domain.demo.id
  account_name  = "admin"
  account_login = "admin"
  resources = [
    "${wallix-bastion_device.demo.device_name}:${wallix-bastion_device_service.demo.service_name}"
  ]
}

# Configure a credential on account of global domain
resource "wallix-bastion_domain_account_credential" "demo" {
  domain_id  = wallix-bastion_domain_account.demo.domain_id
  account_id = wallix-bastion_domain_account.demo.id
  type       = "password"
  password   = random_string.demo.result

}

# Configure a service on device
resource "wallix-bastion_device_service" "demo" {
  service_name      = "demossh"
  device_id         = wallix-bastion_device.demo.id
  connection_policy = "SSH"
  port              = 22
  protocol          = "SSH"
  subprotocols = [
    "SSH_SHELL_SESSION"
  ]
  global_domains = [
    wallix-bastion_domain.demo.domain_name
  ]
}

# Configure a target group
resource "wallix-bastion_targetgroup" "demo" {
  group_name = random_pet.group.id
  session_accounts {
    account     = wallix-bastion_domain_account.demo.account_name
    domain      = wallix-bastion_domain.demo.domain_name
    domain_type = "global"
    device      = wallix-bastion_device.demo.device_name
    service     = wallix-bastion_device_service.demo.service_name
  }
}
