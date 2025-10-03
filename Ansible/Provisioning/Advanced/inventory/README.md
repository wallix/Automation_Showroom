# WALLIX Bastion Inventories

This directory contains different inventory configurations for WALLIX Bastion deployments.

## Available Inventories

### 1. `development`

- **Purpose**: Development and testing environment
- **Target**: Generic development bastion
- **Usage**: `ansible-playbook -i inventory/development <playbook>`

### 2. `test_bastion`

- **Purpose**: Test environment with direct bastion access
- **Target**: Direct access to bastion node at `192.168.1.75`
- **Usage**: `ansible-playbook -i inventory/test_bastion <playbook>`

### 3. `production`

- **Purpose**: Production environment configuration
- **Target**: Load balancer at `bastion-lab.local` with fallback to specific nodes
- **Usage**: `ansible-playbook -i inventory/production <playbook>`

### 4. `production_lb`

- **Purpose**: Production load balancer specific configuration
- **Target**: Dedicated load balancer configuration
- **Usage**: `ansible-playbook -i inventory/production_lb <playbook>`

## Example Usage

### Test Deployment (Real Environment)

```bash
# Using production load balancer
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/production playbooks/test_deploiement_reel.yml -v

# Using test bastion direct access
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/test_bastion playbooks/test_deploiement_reel.yml -v

# Using production load balancer (dedicated config)
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/production_lb playbooks/test_deploiement_reel.yml -v
```

### Full Cleanup

```bash
# Production environment cleanup
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/production test_cleanup_full.yml -v

# Test environment cleanup
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/test_bastion test_cleanup_full.yml -v
```

### Deployment

```bash
# Deploy to production
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/production deploy.yml --ask-vault-pass

# Deploy to test environment
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/test_bastion deploy.yml
```

## Security Notes

- **Production environments** should use `ansible-vault` for sensitive information
- **SSL verification** should be enabled in production with valid certificates
- **Passwords** should never be stored in plain text in inventory files

## Network Configuration

### Load Balancer Setup

- **Primary**: `bastion-lab.local` (Load Balancer)
- **Nodes**: `192.168.1.75`, `192.168.1.76` (if direct access needed)
- **Port**: 443 (HTTPS)

### Direct Access

- **Test Node**: `192.168.1.75:443`
- **Purpose**: Direct testing and troubleshooting
