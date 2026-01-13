# Ansible Provisioning Project

Production-ready provisioning framework for WALLIX Bastion using the `wallix.pam` Ansible collection.

## Overview

This project provides complete automation for WALLIX Bastion provisioning including:

- Device, service, and account management
- User and user group creation
- Authorization and target group configuration
- Global domains and accounts
- Timeframe definitions

## Quick Start

### Prerequisites

```bash
cd Ansible/provisioning

# Install collection dependencies
make deps

# Create vault password file
echo "your_vault_password" > /tmp/.vault_pass
chmod 600 /tmp/.vault_pass
```

### Demo Provisioning

```bash
# Test authentication
make auth BASTION_HOST=10.10.122.15

# Run demo provisioning
make demo BASTION_HOST=10.10.122.15

# Clean up demo resources
make cleanup-demo BASTION_HOST=10.10.122.15
```

### Enterprise Provisioning

```bash
# Full enterprise dataset
make enterprise BASTION_HOST=10.10.122.15

# Quick run (no confirmation)
make enterprise-quick BASTION_HOST=10.10.122.15

# Clean up enterprise resources
make cleanup-enterprise BASTION_HOST=10.10.122.15
```

## Project Structure

```text
provisioning/
├── Makefile                    # Build and automation targets
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Collection dependencies
│
├── playbooks/
│   ├── demo-provision.yml      # Demo provisioning
│   ├── enterprise-provision.yml # Enterprise provisioning
│   ├── provision-full.yml      # Complete infrastructure
│   ├── test-auth.yml           # Authentication testing
│   └── operational/
│       ├── cleanup.yml         # Resource cleanup
│       ├── health-check.yml    # System health checks
│       └── test-collection-readonly.yml
│
├── inventories/
│   ├── dev/                    # Development environment
│   │   ├── hosts.ini
│   │   └── group_vars/all/
│   │       ├── main.yml        # Configuration
│   │       └── vault.yml       # Encrypted credentials
│   ├── test/                   # Test environment
│   └── prod/                   # Production environment
│
└── vars/data/
    ├── demo/                   # Demo dataset
    │   ├── infrastructure.yml  # Devices, services, accounts
    │   ├── users.yml           # Users, groups, authorizations
    │   └── cleanup_patterns.yml
    ├── enterprise/             # Enterprise dataset
    │   ├── infrastructure.yml  # 49 devices, 59 services
    │   ├── users.yml           # 40 users, 18 groups
    │   ├── authorizations.yml  # 32 authorizations
    │   ├── domains.yml         # 4 domains
    │   ├── target_groups.yml   # 35 target groups
    │   └── cleanup_patterns.yml
    └── templates/              # Resource templates
        ├── device-template.yml
        ├── domain-template.yml
        └── authorization-template.yml
```

## Make Targets

| Target                    | Description                         |
| ------------------------- | ----------------------------------- |
| `make help`               | Show all available targets          |
| `make deps`               | Install collection dependencies     |
| `make lint`               | Run ansible-lint and yamllint       |
| `make auth`               | Test authentication                 |
| `make demo`               | Demo provisioning (interactive)     |
| `make demo-quick`         | Demo provisioning (no confirmation) |
| `make enterprise`         | Enterprise provisioning             |
| `make enterprise-quick`   | Enterprise (no confirmation)        |
| `make cleanup-demo`       | Cleanup demo resources              |
| `make cleanup-enterprise` | Cleanup enterprise resources        |
| `make cleanup-dry-run`    | Preview cleanup (no changes)        |
| `make ops-health`         | Run health checks                   |

## Vault Setup

Store credentials in encrypted vault files:

```bash
# Create vault file
ansible-vault create inventories/dev/group_vars/all/vault.yml

# Required contents:
vault_wallix_username: admin
vault_wallix_password: YourSecurePassword123!
```

## Datasets

### Demo Dataset

Quick testing with minimal resources:

- 6 Devices (web, database, application servers)
- 8 Services (SSH, RDP, PostgreSQL, MySQL)
- 7 Users (admin, operators, developers)
- 5 User Groups
- 7 Authorizations
- 3 Timeframes

### Enterprise Dataset

Realistic enterprise configuration:

- 49 Devices across 6 environments (Prod, Staging, Dev, CI/CD, Security, Network)
- 59 Services with full protocol coverage
- 40 Users with role-based access
- 18 User Groups
- 35 Target Groups
- 32 Authorizations
- 6 Timeframes
- 4 Global Domains (Active Directory, LDAP)

## Playbook Usage

### Full Provisioning

```bash
ansible-playbook playbooks/provision-full.yml \
  -i inventories/dev/hosts.ini \
  -e wallix_bastion_host=10.10.122.15 \
  -e @vars/data/demo/infrastructure.yml \
  -e @vars/data/demo/users.yml \
  --vault-password-file /tmp/.vault_pass
```

### Selective Provisioning (Tags)

```bash
# Only devices
ansible-playbook playbooks/provision-full.yml \
  -e wallix_bastion_host=10.10.122.15 \
  --vault-password-file /tmp/.vault_pass \
  --tags devices

# Only users and authorizations
ansible-playbook playbooks/provision-full.yml \
  --tags users,authorizations
```

### Cleanup with Dry Run

```bash
# Preview what would be deleted
ansible-playbook playbooks/operational/cleanup.yml \
  -e wallix_bastion_host=10.10.122.15 \
  -e cleanup_mode=dry-run \
  --vault-password-file /tmp/.vault_pass

# Execute cleanup
ansible-playbook playbooks/operational/cleanup.yml \
  -e cleanup_mode=execute
```

## Collection Roles

| Role                     | Purpose                                   |
| ------------------------ | ----------------------------------------- |
| `wallix-auth`            | API authentication and session management |
| `wallix-devices`         | Device, service, and account management   |
| `wallix-users`           | User and user group management            |
| `wallix-authorizations`  | Target groups and authorizations          |
| `wallix-global-domains`  | Global domain configuration               |
| `wallix-global-accounts` | Domain-level service accounts             |
| `wallix-timeframes`      | Time-based access restrictions            |
| `wallix-cleanup`         | Safe resource cleanup                     |

## Environment Variables

| Variable            | Default                     | Description         |
| ------------------- | --------------------------- | ------------------- |
| `CURRENT_INVENTORY` | `inventories/dev/hosts.ini` | Target inventory    |
| `BASTION_HOST`      | `10.10.122.15`              | Bastion IP/hostname |
| `VAULT_FILE`        | `/tmp/.vault_pass`          | Vault password file |
| `VERBOSITY`         | `-v`                        | Ansible verbosity   |

## Troubleshooting

### Authentication Failed

```bash
# Verify credentials
make auth BASTION_HOST=10.10.122.15

# Check vault contents
ansible-vault view inventories/dev/group_vars/all/vault.yml
```

### Collection Not Found

```bash
# Reinstall collection
make deps
```

### Resource Already Exists

The roles are idempotent - existing resources are updated, not duplicated.

### Cleanup Not Deleting Resources

Verify cleanup patterns match resource names in `vars/data/*/cleanup_patterns.yml`.

## Security

- Credentials stored in Ansible Vault
- Never commit vault passwords
- Use environment-specific inventories
- Rotate API credentials regularly

## Requirements

| Component      | Version |
| -------------- | ------- |
| Ansible Core   | ≥ 2.15  |
| Python         | ≥ 3.9   |
| WALLIX Bastion | ≥ 10.0  |

## See Also

- [wallix-ansible-collection](../wallix-ansible-collection/) - Core roles and plugins
- [Data Templates](vars/data/templates/) - Resource templates
- [Enterprise Dataset](vars/data/enterprise/) - Enterprise configuration
