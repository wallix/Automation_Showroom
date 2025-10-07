#!/bin/bash
#
# Create Ansible Vault for WALLIX Bastion credentials
#

set -e

echo "============================================"
echo "  WALLIX Bastion - Ansible Vault Setup"
echo "============================================"
echo ""

# Check if ansible-vault is available
if ! command -v ansible-vault &> /dev/null; then
    echo "Error: ansible-vault not found. Please install Ansible first."
    exit 1
fi

# Create group_vars directory structure
echo "Creating directory structure..."
mkdir -p group_vars/wallix_bastions

# Prompt for passwords
echo ""
echo "Enter credentials for WALLIX Bastion:"
echo ""
read -r -p "wabadmin SSH password: " -s WABADMIN_PASS
echo ""
read -r -p "wabsuper become password: " -s WABSUPER_PASS
echo ""
echo ""

# Create vault file content
VAULT_CONTENT="---
# WALLIX Bastion Credentials
# Encrypted with Ansible Vault

vault_wabadmin_password: \"$WABADMIN_PASS\"
vault_wabsuper_password: \"$WABSUPER_PASS\"
"

# Create unencrypted vars file
VARS_CONTENT="---
# WALLIX Bastion Variables
# References encrypted vault variables

ansible_password: \"{{ vault_wabadmin_password }}\"
ansible_become_password: \"{{ vault_wabsuper_password }}\"
"

# Write vars file (unencrypted)
echo "$VARS_CONTENT" > group_vars/wallix_bastions/vars.yml
echo "✓ Created group_vars/wallix_bastions/vars.yml"

# Create temporary file with vault content
TEMP_VAULT=$(mktemp)
echo "$VAULT_CONTENT" > "$TEMP_VAULT"

# Encrypt vault file
echo ""
echo "Now you will be prompted to create a vault password."
echo "This password will be used to encrypt/decrypt the credentials."
echo ""
ansible-vault encrypt "$TEMP_VAULT" --output=group_vars/wallix_bastions/vault.yml

# Clean up
rm -f "$TEMP_VAULT"

echo ""
echo "============================================"
echo "  Vault created successfully!"
echo "============================================"
echo ""
echo "Files created:"
echo "  - group_vars/wallix_bastions/vault.yml (encrypted)"
echo "  - group_vars/wallix_bastions/vars.yml (references)"
echo ""
echo "Usage:"
echo "  ansible-playbook -i inventory.ini example_playbook.yml --ask-vault-pass"
echo ""
echo "To view vault contents:"
echo "  ansible-vault view group_vars/wallix_bastions/vault.yml"
echo ""
echo "To edit vault:"
echo "  ansible-vault edit group_vars/wallix_bastions/vault.yml"
echo ""
