# Two Windows jump servers able to run the same program.
resource "wallix-bastion_device" "rds01" {
  device_name = "${local.name}-rds01"
  host        = var.jump_server_hosts[0]
  description = "Automation Showroom: cluster member"
}

resource "wallix-bastion_device_service" "rds01" {
  device_id         = wallix-bastion_device.rds01.id
  service_name      = "RDP"
  protocol          = "RDP"
  port              = 3389
  connection_policy = "RDP"
  global_domains    = [wallix-bastion_domain.rds.domain_name]
}

resource "wallix-bastion_device" "rds02" {
  device_name = "${local.name}-rds02"
  host        = var.jump_server_hosts[1]
  description = "Automation Showroom: cluster member"
}

resource "wallix-bastion_device_service" "rds02" {
  device_id         = wallix-bastion_device.rds02.id
  service_name      = "RDP"
  protocol          = "RDP"
  port              = 3389
  connection_policy = "RDP"
  global_domains    = [wallix-bastion_domain.rds.domain_name]
}

# Service account that opens the RDP session on either jump server.
resource "wallix-bastion_domain" "rds" {
  domain_name = "${local.name}.lab"
  description = "Automation Showroom: cluster"
}

resource "wallix-bastion_domain_account" "rds" {
  domain_id     = wallix-bastion_domain.rds.id
  account_name  = var.jump_account_login
  account_login = var.jump_account_login
  resources = [
    "${wallix-bastion_device.rds01.device_name}:${wallix-bastion_device_service.rds01.service_name}",
    "${wallix-bastion_device.rds02.device_name}:${wallix-bastion_device_service.rds02.service_name}",
  ]
}

resource "wallix-bastion_domain_account_credential" "rds" {
  domain_id  = wallix-bastion_domain_account.rds.domain_id
  account_id = wallix-bastion_domain_account.rds.id
  type       = "password"
  password   = random_password.rds_account.result
}

# Demo value: a real account needs its real password.
resource "random_password" "rds_account" {
  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

locals {
  # The account on each jump server, as account@domain@device:service.
  account = "${wallix-bastion_domain_account.rds.account_name}@${wallix-bastion_domain.rds.domain_name}"
  rds01   = "${local.account}@${wallix-bastion_device.rds01.device_name}:${wallix-bastion_device_service.rds01.service_name}"
  rds02   = "${local.account}@${wallix-bastion_device.rds02.device_name}:${wallix-bastion_device_service.rds02.service_name}"
}

resource "wallix-bastion_cluster" "rds" {
  cluster_name = "${local.name}-rds"
  description  = "Automation Showroom: jump servers of the application"
  accounts     = [local.rds01, local.rds02]
}

# Standard application: its target is the cluster, with the program to run on each member.
resource "wallix-bastion_application" "app" {
  application_name  = local.name
  description       = "Automation Showroom: application published on a cluster"
  connection_policy = "RDP"
  target            = wallix-bastion_cluster.rds.cluster_name

  paths {
    target  = local.rds01
    program = var.program
  }

  paths {
    target  = local.rds02
    program = var.program
  }
}
