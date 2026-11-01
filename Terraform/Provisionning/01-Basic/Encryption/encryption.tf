# Seal state and mode of the encryption, read at plan time.
data "wallix-bastion_encryption" "current" {}

# A Bastion already set up can't be created again: Terraform takes over its encryption with an import.
import {
  to = wallix-bastion_encryption.main
  id = "encryption"
}

# A change of new_passphrase sends current_passphrase -> new_passphrase to the Bastion.
resource "wallix-bastion_encryption" "main" {
  current_passphrase = var.current_passphrase
  new_passphrase     = var.new_passphrase
}
