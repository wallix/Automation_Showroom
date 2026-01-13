#!/bin/bash
#
# Create Ansible Vault for Bastion Proxy Setup
#

set -e

echo "============================================"
echo "  WALLIX Bastion Proxy - Vault Setup"
echo "============================================"
echo ""

# Check if ansible-vault is available
if ! command -v ansible-vault &> /dev/null; then
    echo "Error: ansible-vault not found. Please install Ansible first."
    exit 1
fi

# Create group_vars directory structure
echo "Creating directory structure..."
mkdir -p group_vars/bastion
mkdir -p group_vars/remote_servers

# Prompt for passwords
echo ""
echo "Enter credentials:"
echo ""
read -r -p "WALLIX Bastion admin (wabadmin) password: " -s BASTION_PASS
echo ""
read -r -p "WALLIX proxy user (admin) password: " -s PROXY_PASS
echo ""
echo ""

# Create bastion vault file content
BASTION_VAULT_CONTENT="---
# WALLIX Bastion Credentials
vault_bastion_password: \"$BASTION_PASS\"
"

# Create bastion vars file
BASTION_VARS_CONTENT="---
# WALLIX Bastion Variables
ansible_password: \"{{ vault_bastion_password }}\"
"

# Create remote servers vault file content
REMOTE_VAULT_CONTENT="---
# WALLIX Proxy User Credentials
# This is the password for the bastion user (e.g., admin) used in proxy connections
vault_proxy_password: \"$PROXY_PASS\"
"

# Create remote servers vars file
REMOTE_VARS_CONTENT="---
# Remote Servers Variables
# Password for WALLIX proxy authentication (bastion user password)
ansible_password: \"{{ vault_proxy_password }}\"
"

# Write bastion vars file (unencrypted)
echo "$BASTION_VARS_CONTENT" > group_vars/bastion/vars.yml
echo "✓ Created group_vars/bastion/vars.yml"

# Write remote servers vars file (unencrypted)
echo "$REMOTE_VARS_CONTENT" > group_vars/remote_servers/vars.yml
echo "✓ Created group_vars/remote_servers/vars.yml"

# Create temporary files with vault content
TEMP_BASTION=$(mktemp)
TEMP_REMOTE=$(mktemp)
echo "$BASTION_VAULT_CONTENT" > "$TEMP_BASTION"
echo "$REMOTE_VAULT_CONTENT" > "$TEMP_REMOTE"

# Encrypt vault files
echo ""
echo "Now you will be prompted to create a vault password."
echo "This password will be used to encrypt/decrypt all credentials."
echo ""

# Encrypt bastion vault
ansible-vault encrypt "$TEMP_BASTION" --output=group_vars/bastion/vault.yml
echo "✓ Created group_vars/bastion/vault.yml (encrypted)"

# Encrypt remote servers vault with same password
ansible-vault encrypt "$TEMP_REMOTE" --output=group_vars/remote_servers/vault.yml
echo "✓ Created group_vars/remote_servers/vault.yml (encrypted)"

# Clean up
rm -f "$TEMP_BASTION" "$TEMP_REMOTE"

echo ""
echo "============================================"
echo "  Vault created successfully!"
echo "============================================"
echo ""
echo "Files created:"
echo "  - group_vars/bastion/vault.yml (encrypted)"
echo "  - group_vars/bastion/vars.yml (references)"
echo "  - group_vars/remote_servers/vault.yml (encrypted)"
echo "  - group_vars/remote_servers/vars.yml (references)"
echo ""
echo "Usage:"
echo "  # Test bastion administrative connection"
echo "  ansible bastion -i inventory.ini -m ping --ask-vault-pass"
echo ""
echo "  # Test WALLIX proxy connection to remote servers"
echo "  ansible remote_servers -i inventory.ini -m ping --ask-vault-pass"
echo ""
echo "  # Test manual SSH with WALLIX syntax"
echo "  ssh -p 22 'root@10.0.1.10@z4g4:SSH:test:admin@192.168.1.75'"
echo ""
echo "  # Run full playbook"
echo "  ansible-playbook -i inventory.ini proxy_example.yml --ask-vault-pass"
echo ""
echo "To view vault contents:"
echo "  ansible-vault view group_vars/bastion/vault.yml"
echo "  ansible-vault view group_vars/remote_servers/vault.yml"
echo ""
echo "To edit vault:"
echo "  ansible-vault edit group_vars/bastion/vault.yml"
echo "  ansible-vault edit group_vars/remote_servers/vault.yml"
echo ""
