# WALLIX Ansible Automation

Comprehensive Ansible automation for WALLIX Bastion / WALLIX PAM deployment, configuration, and management.

## Overview

This directory contains production-ready Ansible tools for automating WALLIX Bastion operations:

| Component                                               | Description                                        | Status        |
| ------------------------------------------------------- | -------------------------------------------------- | ------------- |
| [wallix-ansible-collection](wallix-ansible-collection/) | Reusable Ansible collection with roles and plugins | ✅ Production |
| [provisioning](provisioning/)                           | Complete provisioning project with datasets        | ✅ Production |
| [bastion-proxy](bastion-proxy/)                         | Use Bastion as SSH proxy for Ansible               | ✅ Production |
| [become-plugin](become-plugin/)                         | Custom become plugin for privilege escalation      | ✅ Production |
| [cicd-integration](cicd-integration/)                   | GitLab CI/CD integration example                   | 🔧 Demo       |
| [examples/basic-api](examples/basic-api/)               | Basic API usage examples                           | 📚 Learning   |

## Quick Start

### 1. Provisioning (Recommended)

```bash
cd provisioning
make deps                    # Install collection
make auth                    # Test authentication
make demo                    # Provision demo resources
```

### 2. Collection Installation

```bash
# From Galaxy (when published)
ansible-galaxy collection install wallix.pam

# From local source
cd wallix-ansible-collection
ansible-galaxy collection build
ansible-galaxy collection install wallix-pam-*.tar.gz
```

## Architecture

```text
Ansible/
├── wallix-ansible-collection/    # Core collection
│   ├── plugins/                  # Modules and lookup plugins
│   │   ├── modules/secret.py     # Secret retrieval module
│   │   └── lookup/secret.py      # Secret lookup plugin
│   └── roles/                    # Reusable roles
│       ├── wallix-auth/          # API authentication
│       ├── wallix-devices/       # Device management
│       ├── wallix-users/         # User management
│       ├── wallix-authorizations/# Authorization management
│       ├── wallix-cleanup/       # Resource cleanup
│       └── ...
│
├── provisioning/                 # Production provisioning
│   ├── playbooks/                # Ready-to-use playbooks
│   ├── inventories/              # Environment inventories
│   ├── vars/data/                # Configuration datasets
│   └── Makefile                  # Automation targets
│
├── bastion-proxy/                # SSH proxy configuration
├── become-plugin/                # Privilege escalation
├── cicd-integration/             # CI/CD examples
└── examples/                     # Learning resources
```

## Components

### WALLIX Ansible Collection

The core collection providing:

- **Roles**: Modular automation for all WALLIX resources
- **Plugins**: Secret retrieval (module + lookup)
- **Documentation**: Usage examples and API reference

→ [Collection Documentation](wallix-ansible-collection/README.md)

### Provisioning Project

Production-ready provisioning with:

- **Demo dataset**: Quick testing with sample data
- **Enterprise dataset**: Realistic enterprise configuration
- **Makefile automation**: Simplified operations
- **Multi-environment**: Dev, test, production support

→ [Provisioning Guide](provisioning/README.md)

### Bastion as SSH Proxy

Use WALLIX Bastion as transparent SSH proxy:

- Native Ansible ProxyCommand support
- Vault-encrypted credentials
- Mixed environment support

→ [Proxy Setup Guide](bastion-proxy/README.md)

### Become Plugin

Custom privilege escalation through Bastion:

- `wabsuper` integration
- Transparent sudo replacement
- Session tracking

→ [Plugin Documentation](become-plugin/README.md)

## Requirements

| Component      | Version |
| -------------- | ------- |
| Ansible Core   | ≥ 2.15  |
| Python         | ≥ 3.9   |
| WALLIX Bastion | ≥ 10.0  |

## Configuration

### Vault Setup

All examples use Ansible Vault for credentials:

```bash
# Create vault password file
echo "your-vault-password" > /tmp/.vault_pass
chmod 600 /tmp/.vault_pass

# Create encrypted credentials
ansible-vault create inventories/dev/group_vars/all/vault.yml
```

### Environment Variables

| Variable                      | Description            | Default            |
| ----------------------------- | ---------------------- | ------------------ |
| `ANSIBLE_VAULT_PASSWORD_FILE` | Path to vault password | `/tmp/.vault_pass` |
| `WALLIX_BASTION_HOST`         | Bastion hostname/IP    | -                  |
| `WALLIX_BASTION_PORT`         | API port               | `443`              |

## Troubleshooting

### Authentication Issues

```bash
# Test API connectivity
make auth

# Verify vault decryption
ansible-vault view inventories/dev/group_vars/all/vault.yml
```

### Collection Not Found

```bash
# Verify collection path
ansible-galaxy collection list

# Reinstall collection
make deps
```

### SSL Certificate Errors

```yaml
# In playbook or inventory
wallix_api:
  validate_certs: false  # Development only
```

## Security

- Never commit vault passwords or API keys
- Use vault-encrypted credentials in production
- Rotate API keys regularly
- See [Security Guidelines](../CONTRIBUTING.md#security)

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

MPL-2.0 (Mozilla Public License 2.0) - See [LICENSE](../LICENSE)
