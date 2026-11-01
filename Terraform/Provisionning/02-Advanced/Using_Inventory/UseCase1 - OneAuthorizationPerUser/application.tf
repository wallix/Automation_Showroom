locals {
  rds = local.inventory.applications.rds_server

  # One application per VM with a url.
  app_vms = { for k, vm in local.vms : k => vm if vm.url != "" }

  # Jump server path of the applications: <account>@<domain>@<device>:<service> of the RDS server.
  rds_target = "${wallix-bastion_domain_account.rds.account_name}@${wallix-bastion_domain.demo.domain_name}@${wallix-bastion_device.vms[local.rds].device_name}:${wallix-bastion_device_service.vms[local.rds].service_name}"
}

# Service account that opens the RDP session on the RDS server, where AppDriver runs.
resource "wallix-bastion_domain_account" "rds" {
  domain_id     = wallix-bastion_domain.demo.id
  account_name  = local.inventory.applications.rds_account
  account_login = local.inventory.applications.rds_account
  resources     = ["${wallix-bastion_device.vms[local.rds].device_name}:${wallix-bastion_device_service.vms[local.rds].service_name}"]
}

# Placeholder password: set the real password of the RDS account.
resource "wallix-bastion_domain_account_credential" "rds" {
  domain_id  = wallix-bastion_domain_account.rds.domain_id
  account_id = wallix-bastion_domain_account.rds.id
  type       = "password"
  password   = random_password.rds_account.result
}

# Standard application: AppDriver opens the url; the user's account (target group) is the one injected.
resource "wallix-bastion_application" "apps" {
  for_each = local.app_vms

  application_name  = "${each.value.name}-APP"
  connection_policy = "RDP"
  global_domains    = [wallix-bastion_domain.demo.domain_name]
  parameters        = "-e URL=${each.value.url}"
  target            = local.rds_target

  paths {
    target      = local.rds_target
    program     = local.inventory.applications.appdriver_path
    working_dir = local.inventory.applications.working_dir
  }
}
