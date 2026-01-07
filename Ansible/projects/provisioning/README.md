# Ansible Provisioning Project

Production-ready provisioning framework for WALLIX Bastion, organized by environment and using the centralized `wallix-ansible-collection`.

## Quick Start

### Installation
```bash
cd Ansible/projects/provisioning
make deps
```

### Testing (Development)
```bash
make lint                  # Validate syntax
make auth                  # Test credentials and API connectivity
make provision             # Run full provisioning (with confirmation)
```

### Production Deployment
```bash
CURRENT_INVENTORY=inventories/prod/hosts.ini make provision
```

## Structure

- `playbooks/` — Main orchestration (provision-full.yml, provision-incremental.yml)
  - `operational/` — Health checks, backup, restore, user onboarding, device provisioning
- `inventories/{dev,test,prod}/` — Environment-specific hosts and variables
  - `group_vars/` — Group-level defaults
  - `host_vars/` — Host-specific overrides
- `vars/data/{users,devices,domains}/` — Data models (templates and examples)
- `roles/` — Project-specific roles (if any; prefer collection roles)
- `files/`, `templates/` — Static assets

## Inventory Format

Each environment (dev/test/prod) has:
```ini
[bastions]
bastion-1 wallix_bastion_host=10.x.x.x wallix_bastion_port=443

[bastions:vars]
wallix_bastion_protocol=https
wallix_auth_method=credentials
```

## Authentication

- Uses `wallix.bastion.auth` role from `wallix-ansible-collection`
- Root API endpoint: `POST /api` with basic auth
- Session cookie (`wab_session_id`) reused for subsequent requests
- Credentials via vault or `-e` extra variables

## Playbooks

### provision-full.yml
Creates or updates all infrastructure:
1. Authenticate (login, get session)
2. Create global domains
3. Create global accounts
4. Create devices and services
5. Create users with advanced credentials (SSH, X.509)
6. Create authorizations

### provision-incremental.yml
Idempotent updates to existing infrastructure.

### operational/
- `health-check.yml` — API status, session validation, connectivity
- `backup-config.yml` — Export device/user/authorization configs
- `restore-config.yml` — Restore from backup
- `user-onboarding.yml` — Add user with credentials and group assignments
- `device-provisioning.yml` — Add device with service, account, and authorization setup

## Variables

### From Vault (group_vars/all/vault.yml)
```yaml
vault_wallix_username: admin
vault_wallix_password: "***"
vault_wallix_bastion_host: "10.x.x.x"
```

### From Inventory or -e
```bash
ansible-playbook playbooks/provision-full.yml -i inventories/test/hosts.ini \
  -e wallix_bastion_host=10.x.x.x \
  -e vault_wallix_username=admin \
  -e vault_wallix_password='***'
```

## Makefile Targets

- `make help` — Show all targets
- `make deps` — Install Python + Ansible dependencies
- `make lint` — Run ansible-lint and yamllint
- `make auth` — Test bastion connectivity and authentication
- `make provision` — Run full provisioning
- `make ops-health` — Health check
- `make clean` — Remove caches and temp files

## Data Templates

Create users, devices, domains from `vars/data/` templates:

### User Template
```yaml
name: "example_user"
email: "user@example.com"
profile: "user"
groups: ["Admin_Group"]
user_auths: ["local_password", "local_sshkey"]
credentials:
  local_password: "***"
  local_sshkey: "ssh-rsa AAAA..."
```

### Device Template
```yaml
name: "prod-server-01"
host: "10.1.1.100"
services:
  - name: "SSH"
    protocol: "SSH"
    port: 22
accounts:
  - login: "admin"
    domain: "prod.local"
```

### Domain Template
```yaml
name: "PROD_AD"
domain_real_name: "prod.company.local"
enable_password_change: true
```

## See Also

- [wallix-ansible-collection](../../wallix-ansible-collection/) — Core roles and plugins
- [../demos/](../demos/) — Demo playbooks
- [../extras/](../extras/) — Become plugin, bastion-as-proxy examples
