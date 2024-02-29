// Get get Access Manager AMI ID
data "aws_ami" "am_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["access-manager-${var.acces_manager_version}-aws"]
  }

  owners = ["519101999238"] # WALLIX
}

// Get get Bastion / Session Manager AMI ID
data "aws_ami" "bastion_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bastion-${var.bastion_version}-aws"]
  }

  owners = ["519101999238"] # WALLIX

}

// Generate a random_id for the project
resource "random_id" "server" {
  byte_length = 4

}

// Generate a project name
locals {

  project_name = "${var.project_name}-${random_id.server.id}"

}

// Generates a secure private key for SSH connection to instances
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

// Create the Key Pair on AWS
resource "aws_key_pair" "key_pair" {
  key_name   = local.project_name
  public_key = tls_private_key.key_pair.public_key_openssh

}

// Save file locally with right permission
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.key_pair.private_key_pem
  filename        = "private_key.pem"
  file_permission = "400"

}


// Generate random passwords

resource "random_string" "password_wabadmin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}

resource "random_string" "password_wabsuper" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}

resource "random_string" "password_wabupgrade" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}

// Generate Wallix Cloud Init file from template

data "template_file" "am" {
  template = file("cloud-init-conf-WALLIX_AM.tpl")
  vars = {
    wallix_sshkey               = tls_private_key.key_pair.public_key_openssh
    wallix_sshkey               = tls_private_key.key_pair.public_key_openssh
    wallix_password_wabadmin    = random_string.password_wabadmin.id
    wallix_password_wabsuper    = random_string.password_wabsuper.id
    wallix_password_wabupgrade  = random_string.password_wabupgrade.id
    http_host_trusted_hostnames = aws_lb.front_am.dns_name
  }

}

data "template_file" "bastion" {
  template = file("cloud-init-conf-WALLIX_BASTION.tpl")
  vars = {
    wallix_sshkey              = tls_private_key.key_pair.public_key_openssh
    wallix_password_wabadmin   = random_string.password_wabadmin.id
    wallix_password_wabsuper   = random_string.password_wabsuper.id
    wallix_password_wabupgrade = random_string.password_wabupgrade.id

  }

}