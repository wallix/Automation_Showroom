terraform {
  required_version = ">= 1.9.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.3"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.5.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.5"
    }
  }
}

// Define Wallix Services Accounts
locals {
  wallix_accounts = ["wabadmin", "wabsuper", "wabupgrade"]

}

// Generate random passwords

resource "random_password" "password" {
  for_each         = toset(local.wallix_accounts)
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  min_numeric      = 1
  override_special = "-_=+"

}

resource "random_password" "webui_password" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  min_numeric      = 1
  override_special = "-_=+"

}


resource "random_password" "cryptokey_password" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  min_numeric      = 1
  override_special = "-_=+"

}

data "cloudinit_config" "wallix_appliance" {
  gzip          = var.to_gzip
  base64_encode = var.to_base64_encode
  part {
    filename     = "cloud-config-base.yaml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/cloud-init-conf-WALLIX_BASE.tpl")
  }
  dynamic "part" {
    for_each = var.set_service_user_password ? ["create"] : []
    content {
      filename     = "cloud-config-users.yaml"
      content_type = "text/cloud-config"
      content = templatefile("${path.module}/cloud-init-conf-WALLIX_ACCOUNTS.tpl", {
        wabadmin_password   = "${random_password.password["wabadmin"].result}",
        wabsuper_password   = "${random_password.password["wabsuper"].result}",
        wabupgrade_password = "${random_password.password["wabupgrade"].result}"
        }
      )
    }
  }
  dynamic "part" {
    for_each = var.use_of_lb ? ["create"] : []
    content {
      filename     = "cloud-config-lb.yaml"
      content_type = "text/cloud-config"
      content = templatefile("${path.module}/cloud-init-conf-WALLIX_LB.tpl", {
        http_host_trusted_hostnames = lower("${var.http_host_trusted_hostnames}"),
        }
      )
    }
  }

  dynamic "part" {
    for_each = var.set_webui_password_and_crypto ? ["create"] : []
    content {
      filename     = "webadminpass-crypto.py"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/webadminpass-crypto.py", {
        webui_password     = "${random_password.webui_password.result}",
        cryptokey_password = "${random_password.cryptokey_password.result}"
        }
      )
    }
  }

}