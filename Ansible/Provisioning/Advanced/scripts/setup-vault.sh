#!/bin/bash
# WALLIX Vault Setup and Test Script
# 
# This script helps you:
# 1. Create encrypted Ansible vault with prompted or config-based values
# 2. Test API connection
# 3. Validate credentials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_FILE="$SCRIPT_DIR/../group_vars/all/vault.yml"
TEST_PLAYBOOK="$SCRIPT_DIR/../playbooks/test-connection.yml"
INVENTORY="$SCRIPT_DIR/../inventory/test"
CONFIG_FILE="$SCRIPT_DIR/vault-config.conf"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   WALLIX Bastion - Vault Setup & Test Script                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Function to check if vault is encrypted
is_encrypted() {
    if [ -f "$VAULT_FILE" ]; then
        head -n 1 "$VAULT_FILE" | grep -q '^\$ANSIBLE_VAULT'
        return $?
    fi
    return 1
}

# Function to load config file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "📁 Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# Function to prompt for values
prompt_for_values() {
    echo "🔧 Configuring vault variables..."
    echo ""
    
    # Bastion connection details
    read -r -p "Enter Bastion URL [https://192.168.1.75]: " BASTION_URL
    BASTION_URL=${BASTION_URL:-"https://192.168.1.75"}

    read -r -p "Enter Bastion Username: " BASTION_USERNAME
    while [ -z "$BASTION_USERNAME" ]; do
        echo "❌ Username cannot be empty"
        read -r -p "Enter Bastion Username: " BASTION_USERNAME
    done
    
    read -s -p "Enter Bastion Password: " BASTION_PASSWORD
    echo ""
    while [ -z "$BASTION_PASSWORD" ]; do
        echo "❌ Password cannot be empty"
        read -r -s -p "Enter Bastion Password: " BASTION_PASSWORD
        echo ""
    done

    read -r -p "Verify SSL certificates? [false]: " VERIFY_SSL
    VERIFY_SSL=${VERIFY_SSL:-"false"}
    
    # API connection details
    read -r -p "Enter API timeout (seconds) [30]: " API_TIMEOUT
    API_TIMEOUT=${API_TIMEOUT:-"30"}
    
    # Demo user details
    echo ""
    echo "Demo user configuration:"
    read -r -p "Enter demo username [demo_user]: " DEMO_USERNAME
    DEMO_USERNAME=${DEMO_USERNAME:-"demo_user"}

    read -r -s -p "Enter demo user password: " DEMO_PASSWORD
    echo ""
    while [ -z "$DEMO_PASSWORD" ]; do
        echo "❌ Demo password cannot be empty"
        read -r -s -p "Enter demo user password: " DEMO_PASSWORD
        echo ""
    done

    read -r -p "Enter demo user email [demo@example.com]: " DEMO_EMAIL
    DEMO_EMAIL=${DEMO_EMAIL:-"demo@example.com"}

    read -r -p "Enter demo user profile [user]: " DEMO_PROFILE
    DEMO_PROFILE=${DEMO_PROFILE:-"user"}
    
    # Target group
    read -r -p "Enter target group for demo [demo_targets]: " TARGET_GROUP
    TARGET_GROUP=${TARGET_GROUP:-"demo_targets"}
}

# Function to create vault content
create_vault_content() {
    cat > "$VAULT_FILE" << EOF
---
# WALLIX Bastion Configuration (standardized format)
vault_wallix_bastion_url: "$BASTION_URL"
vault_wallix_bastion_host: "$(echo "$BASTION_URL" | sed 's|https\?://||' | sed 's|:.*||')"
vault_wallix_bastion_port: "$(echo "$BASTION_URL" | grep -o ':[0-9]*' | sed 's/://' || echo '443')"
vault_wallix_bastion_protocol: "$(echo "$BASTION_URL" | grep -o '^https\?' || echo 'https')"
vault_wallix_username: "$BASTION_USERNAME"
vault_wallix_password: "$BASTION_PASSWORD"

# Legacy format for backward compatibility
wallix_bastion:
  url: "$BASTION_URL"
  username: "$BASTION_USERNAME"
  password: "$BASTION_PASSWORD"
  verify_ssl: $VERIFY_SSL
  timeout: $API_TIMEOUT

# Demo User Configuration
demo_user:
  username: "$DEMO_USERNAME"
  password: "$DEMO_PASSWORD"
  email: "$DEMO_EMAIL"
  profile: "$DEMO_PROFILE"
  groups:
    - "$TARGET_GROUP"

# Additional Configuration
target_groups:
  - name: "$TARGET_GROUP"
    description: "Demo target group for testing"

# API Configuration
api_config:
  timeout: $API_TIMEOUT
  retry_count: 3
  retry_delay: 5
  verify_ssl: $VERIFY_SSL
EOF
}

# Function to save config template
create_config_template() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "📝 Creating config template at $CONFIG_FILE"
        cat > "$CONFIG_FILE" << EOF
# WALLIX Vault Configuration
# Edit these values and re-run the script

# Bastion connection
BASTION_URL="https://192.168.1.75"
BASTION_USERNAME="admin"
BASTION_PASSWORD="your_password_here"
VERIFY_SSL="false"
API_TIMEOUT="30"

# Demo user
DEMO_USERNAME="demo_user"
DEMO_PASSWORD="demo_password_here"
DEMO_EMAIL="demo@example.com"
DEMO_PROFILE="user"
TARGET_GROUP="demo_targets"
EOF
        echo "✅ Config template created. Edit $CONFIG_FILE and re-run this script."
        echo ""
    fi
}

# Main execution
echo "📋 Vault Setup Options:"
echo "1. 📁 Use config file ($CONFIG_FILE)"
echo "2. ⌨️  Manual input (prompted)"
echo "3. 📝 Create config template"
echo ""

read -p "Choose option (1/2/3) [1]: " -n 1 -r SETUP_MODE
echo ""
SETUP_MODE=${SETUP_MODE:-1}

case $SETUP_MODE in
    1)
        if load_config; then
            echo "✅ Configuration loaded from file"
        else
            echo "❌ Config file not found. Creating template..."
            create_config_template
            exit 0
        fi
        ;;
    2)
        prompt_for_values
        ;;
    3)
        create_config_template
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

# Validate required variables
if [ -z "$BASTION_URL" ] || [ -z "$BASTION_USERNAME" ] || [ -z "$BASTION_PASSWORD" ]; then
    echo "❌ Error: Missing required bastion configuration"
    exit 1
fi

if [ -z "$DEMO_USERNAME" ] || [ -z "$DEMO_PASSWORD" ]; then
    echo "❌ Error: Missing required demo user configuration"
    exit 1
fi

# Create vault directory if it doesn't exist
mkdir -p "$(dirname "$VAULT_FILE")"

# Check vault encryption status
echo ""
echo "📋 Vault Status Check:"
echo "   File: $VAULT_FILE"

if [ -f "$VAULT_FILE" ] && is_encrypted; then
    echo "   Status: ✅ Encrypted"
    echo ""
    echo "⚠️  Vault file already exists and is encrypted."
    read -p "Do you want to recreate it? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "ℹ️  Keeping existing vault file."
        echo ""
        echo "To edit the vault:"
        echo "   ansible-vault edit $VAULT_FILE"
        echo ""
        echo "To view the vault:"
        echo "   ansible-vault view $VAULT_FILE"
        echo ""
    else
        echo "🔄 Recreating vault..."
        rm -f "$VAULT_FILE"
    fi
fi

# Create new vault if needed
if [ ! -f "$VAULT_FILE" ] || [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📝 Creating vault content..."
    create_vault_content
    
    echo "🔐 Encrypting vault file..."
    echo ""
    echo "You will be asked to create a vault password."
    echo "⚠️  IMPORTANT: Remember this password - you'll need it to use the playbooks!"
    echo ""
    
    # Encrypt the vault
    ansible-vault encrypt "$VAULT_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Vault created and encrypted successfully!"
        echo ""
        echo "💾 Save your vault password in a password manager!"
        echo ""
    else
        echo ""
        echo "❌ Failed to encrypt vault"
        exit 1
    fi
fi

# Ask user if they want to test the connection
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "🧪 Do you want to test the API connection now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Running connection test..."
    echo ""
    echo "Command: ansible-playbook -i $INVENTORY $TEST_PLAYBOOK --ask-vault-pass"
    echo ""
    
    # Run the test playbook
    ansible-playbook -i "$INVENTORY" "$TEST_PLAYBOOK" --ask-vault-pass
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║   ✅ Connection test completed successfully!                ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
    else
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║   ⚠️  Connection test encountered errors                     ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Troubleshooting tips:"
        echo "1. Verify bastion URL: $BASTION_URL"
        echo "2. Check username/password in vault"
        echo "3. Ensure SSL certificate is valid (or verify_ssl: false)"
        echo "4. Check network connectivity to bastion"
    fi
else
    echo ""
    echo "ℹ️  Skipping connection test."
    echo ""
    echo "To test manually later, run:"
    echo "   ansible-playbook -i $INVENTORY $TEST_PLAYBOOK --ask-vault-pass"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. 📝 Edit vault to modify credentials:"
echo "   ansible-vault edit $VAULT_FILE"
echo ""
echo "2. 🧪 Test connection again:"
echo "   ansible-playbook -i $INVENTORY $TEST_PLAYBOOK --ask-vault-pass"
echo ""
echo "3. 🚀 Run demo playbook:"
echo "   ansible-playbook -i inventory/production playbooks/demo-playbook.yml --ask-vault-pass"
echo ""
echo "4. 📖 View vault contents:"
echo "   ansible-vault view $VAULT_FILE"
echo ""
echo "5. 🔄 Change vault password:"
echo "   ansible-vault rekey $VAULT_FILE"
echo ""
echo "6. ⚙️  Update config file:"
echo "   nano $CONFIG_FILE"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete! Your vault is ready for demo playbook.    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
