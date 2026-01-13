# WALLIX PAM Ansible Collection

[![Ansible Collection](https://img.shields.io/badge/Ansible-Collection-blue?logo=ansible)](https://github.com/wallix/Automation_Showroom)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](../../LICENSE)
[![WALLIX Bastion](https://img.shields.io/badge/WALLIX%20Bastion-10.0%2B-orange)](https://www.wallix.com)

A comprehensive Ansible collection for **WALLIX Privileged Access Management (PAM)** integration. This collection enables seamless automation of WALLIX Bastion configuration, provisioning, and secret management.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Collection Content](#collection-content)
- [Usage Examples](#usage-examples)
- [Configuration Reference](#configuration-reference)
- [Authentication Guide](#authentication-guide)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Overview

The `wallix.pam` collection provides a complete toolkit for automating WALLIX Bastion operations:

- **Provisioning**: Automate device, user, and authorization setup
- **Secret Management**: Securely retrieve passwords and SSH keys at runtime
- **Configuration**: Manage system settings, policies, and timeframes
- **Cleanup**: Safe resource removal with backup capabilities

## ✨ Features

| Category           | Capabilities                                                     |
| ------------------ | ---------------------------------------------------------------- |
| **Authentication** | API credentials, API keys, session management, cookie-based auth |
| **Infrastructure** | Devices, services, local accounts, global domains                |
| **Access Control** | Users, user groups, authorizations, target groups                |
| **Secrets**        | Password/SSH key checkout, checkin, extend operations            |
| **Policies**       | Connection policies, timeframes, access rules                    |
| **Maintenance**    | Cleanup, backups, configuration management                       |

## 📦 Requirements

| Component          | Version |
| ------------------ | ------- |
| Ansible Core       | ≥ 2.15  |
| Python             | ≥ 3.9   |
| WALLIX Bastion     | ≥ 10.0  |
| `requests` library | Latest  |

## Installation

### From Git Repository (Recommended)

Add to your `requirements.yml`:

```yaml
---
collections:
  - name: https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
    type: git
    version: main
```

Then install:

```bash
ansible-galaxy collection install -r requirements.yml
```

### Direct Installation

```bash
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
```

### From Source (Development)

```bash
git clone https://github.com/wallix/Automation_Showroom.git
cd Automation_Showroom/Ansible/wallix-ansible-collection
ansible-galaxy collection build
ansible-galaxy collection install wallix-pam-*.tar.gz
```

> **Note**: For Ansible Automation Platform (AAP) or AWX, include `requirements.yml` in your project root—collections install automatically before job execution.

## Quick Start

### 1. Set Up Authentication

Export your WALLIX Bastion credentials:

```bash
export WALLIX_URL="https://bastion.example.com"
export WALLIX_USER="api-user"
export WALLIX_PASSWORD="your-password"
```

### 2. Create a Simple Playbook

```yaml
---
- name: WALLIX PAM Demo
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Checkout SSH Key from Bastion
      wallix.pam.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "root"
        domain: "local"
        device: "web-server-01"
        state: checkout
        validate_certs: true
      register: wallix_secret
      no_log: true

    - name: Display checkout result
      debug:
        msg: "Retrieved credentials for: {{ wallix_secret.login }}"
```

### 3. Run the Playbook

```bash
ansible-playbook playbook.yml
```

## 📚 Collection Content

### Modules

| Module              | Description                                                         |
| ------------------- | ------------------------------------------------------------------- |
| `wallix.pam.secret` | Retrieve, checkout, checkin, and extend secrets from WALLIX Bastion |

### Lookup Plugins

| Plugin              | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `wallix.pam.secret` | Inline secret retrieval using `account@domain@device` format |

### Roles

| Role                         | Description                                |
| ---------------------------- | ------------------------------------------ |
| `wallix-auth`                | API authentication and session management  |
| `wallix-devices`             | Device and service configuration           |
| `wallix-users`               | User and user group management             |
| `wallix-authorizations`      | Authorization and target group management  |
| `wallix-global-domains`      | Global domain (LDAP/AD) configuration      |
| `wallix-global-accounts`     | Global account management                  |
| `wallix-domains`             | Domain-specific authentication             |
| `wallix-timeframes`          | Timeframe definitions for scheduled access |
| `wallix-connection-policies` | Connection policy management               |
| `wallix-policies`            | Generic policy management                  |
| `wallix-applications`        | Application integration management         |
| `wallix-config`              | Bastion system configuration               |
| `wallix-cleanup`             | Safe resource cleanup with backup          |

## Usage Examples

### Secret Module Operations

#### Checkout (Retrieve Secret)

```yaml
- name: Checkout credentials
  wallix.pam.secret:
    wallix_url: "{{ wallix_url }}"
    username: "{{ wallix_user }}"
    password: "{{ wallix_password }}"
    account: "root"
    domain: "local"
    device: "prod-server-01"
    state: checkout
    validate_certs: true
  register: secret
  no_log: true
```

#### Checkin (Release Secret)

```yaml
- name: Release the secret
  wallix.pam.secret:
    wallix_url: "{{ wallix_url }}"
    username: "{{ wallix_user }}"
    password: "{{ wallix_password }}"
    account: "root"
    device: "prod-server-01"
    state: checkin
    force: true
    comment: "Deployment completed"
```

#### Extend (Renew Checkout Duration)

```yaml
- name: Extend checkout duration
  wallix.pam.secret:
    wallix_url: "{{ wallix_url }}"
    username: "{{ wallix_user }}"
    password: "{{ wallix_password }}"
    account: "root"
    device: "prod-server-01"
    state: extend
```

### Lookup Plugin (Inline Secrets)

```yaml
- name: Deploy configuration with inline secret
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config.ini
  vars:
    db_password: "{{ lookup('wallix.pam.secret', 'app-user@local@db-server') }}"
```

### Dynamic SSH Key Retrieval

```yaml
- hosts: all
  gather_facts: false
  vars:
    ansible_ssh_private_key_file: "/tmp/ssh_key_{{ inventory_hostname }}"

  pre_tasks:
    - name: Fetch SSH Key from WALLIX
      delegate_to: localhost
      wallix.pam.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "ansible"
        domain: "local"
        device: "{{ inventory_hostname }}"
        state: checkout
      register: host_secret
      no_log: true

    - name: Save SSH key to file
      delegate_to: localhost
      ansible.builtin.copy:
        content: "{{ host_secret.ssh_key }}"
        dest: "{{ ansible_ssh_private_key_file }}"
        mode: '0600'
      no_log: true

  tasks:
    - name: Execute remote task
      ansible.builtin.ping:

  post_tasks:
    - name: Cleanup SSH key
      delegate_to: localhost
      ansible.builtin.file:
        path: "{{ ansible_ssh_private_key_file }}"
        state: absent
```

### Using Roles for Provisioning

```yaml
---
- name: Provision WALLIX Bastion
  hosts: bastion
  gather_facts: false

  vars_files:
    - vars/devices.yml
    - vars/users.yml

  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-devices
    - role: wallix.pam.wallix-users
    - role: wallix.pam.wallix-authorizations
```

## ⚙️ Configuration Reference

### Environment Variables

| Variable          | Description                                           |
| ----------------- | ----------------------------------------------------- |
| `WALLIX_URL`      | Bastion API URL (e.g., `https://bastion.example.com`) |
| `WALLIX_USER`     | API username                                          |
| `WALLIX_PASSWORD` | API password                                          |
| `WALLIX_API_KEY`  | API key (alternative to password)                     |

### Core Configuration Variables

```yaml
# Connection settings
wallix_bastion_host: "bastion.example.com"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

# Authentication configuration
wallix_auth:
  initial_auth_method: "credentials"
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
  api_key:
    key: "{{ vault_api_key }}"
    secret: "{{ vault_api_secret }}"
  session:
    use_cookie: true
    auto_renew: true
    max_session_duration: 3600
    cleanup_on_exit: true
  connection:
    verify_ssl: true
    timeout: 30
    retry_count: 3
    retry_delay: 5

wallix_api:
  base_url: "{{ wallix_bastion_protocol }}://{{ wallix_bastion_host }}:{{ wallix_bastion_port }}/api"
```

## Authentication Guide

The collection supports **three credential methods** with automatic fallback:

### Method 1: Ansible Vault (Recommended for Production)

Create encrypted vault file:

```bash
ansible-vault create group_vars/all/vault.yml
```

Add credentials:

```yaml
vault_wallix_username: "api-user"
vault_wallix_password: "secure-password"
vault_api_key: "optional-api-key"
vault_api_secret: "optional-api-secret"
```

Reference in configuration:

```yaml
wallix_bastion_host: "bastion.example.com"
wallix_auth:
  initial_auth_method: "credentials"
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
  connection:
    verify_ssl: true
```

Run with vault:

```bash
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

### Method 2: Plain Variables (Development Only)

```yaml
wallix_bastion_host: "bastion.example.com"
wallix_username: "api-user"
wallix_password: "test-password"

wallix_auth:
  initial_auth_method: "credentials"
```

⚠️ **Never use plain variables in production or commit credentials to version control.**

### Method 3: Environment Variables (CI/CD Pipelines)

Set environment variables:

```bash
export WALLIX_API_USER="api-user"
export WALLIX_API_PASSWORD="secure-password"
export WALLIX_API_KEY="optional-api-key"
```

Run playbook (credentials auto-detected):

```bash
ansible-playbook playbook.yml
```

### Credential Priority Order

The collection checks credentials in this order:

1. Plain variables: `wallix_username`, `wallix_password`
2. Vault variables: `vault_wallix_username`, `vault_wallix_password`
3. Environment variables: `WALLIX_API_USER`, `WALLIX_API_PASSWORD`
4. Defaults: `admin` / empty

### CI/CD Integration Examples

#### GitHub Actions

```yaml
- uses: actions/checkout@v3
- name: Install Ansible
  run: pip install ansible
- name: Run WALLIX Provisioning
  env:
    WALLIX_API_USER: ${{ secrets.WALLIX_USER }}
    WALLIX_API_PASSWORD: ${{ secrets.WALLIX_PASSWORD }}
  run: ansible-playbook playbook.yml
```

#### GitLab CI

```yaml
deploy:
  stage: deploy
  image: python:3.11
  before_script:
    - pip install ansible
  script:
    - ansible-playbook playbook.yml
  variables:
    WALLIX_API_USER: $WALLIX_USER
    WALLIX_API_PASSWORD: $WALLIX_PASSWORD
```

#### Jenkins Pipeline

```groovy
pipeline {
  stages {
    stage('Deploy') {
      environment {
        WALLIX_API_USER = credentials('wallix-user')
        WALLIX_API_PASSWORD = credentials('wallix-password')
      }
      steps {
        sh 'ansible-playbook playbook.yml'
      }
    }
  }
}
```

#### Docker Compose

```yaml
version: '3'
services:
  ansible:
    image: ansible/ansible:latest
    volumes:
      - ./playbooks:/playbooks
    environment:
      - WALLIX_API_USER=${WALLIX_USER}
      - WALLIX_API_PASSWORD=${WALLIX_PASSWORD}
    command: ansible-playbook /playbooks/playbook.yml
```

### Security Best Practices

**✅ Always:**

- Limit API user permissions to minimum required
- Use `no_log: true` for tasks handling credentials
- Enable SSL verification in production (`verify_ssl: true`)
- Use different credentials per environment
- Rotate credentials regularly
- Use vault for production environments

**❌ Never:**

- Use default passwords
- Log credentials in playbook output
- Disable SSL verification in production
- Use the same password across environments
- Share credentials via insecure channels
- Commit plain-text passwords to version control

### Vault Best Practices

- Rotate vault passwords periodically
- Use different vaults for different environments (dev/staging/prod)
- Store vault password securely (password manager, secrets management system)
- Add `*.vault.yml` to `.gitignore` if using separate vault files
- Use vault IDs for multiple vaults

### Troubleshooting Authentication

#### Testing Credential Priority

Enable debug mode to see which credential source is used:

```yaml
wallix_debug:
  enabled: true
  log_requests: true
```

#### Verify Credentials

Test without running full playbook:

```bash
# Test with curl
curl -k -u "username:password" https://bastion.company.com/api/version

# Test with Ansible ad-hoc
ansible localhost -m debug -a "var=wallix_password"
```

#### Common Issues

| Issue                             | Cause                   | Solution                             |
| --------------------------------- | ----------------------- | ------------------------------------ |
| `password is undefined`           | No credentials provided | Set at least one credential method   |
| `Authentication failed`           | Wrong credentials       | Verify username/password are correct |
| `vault_wallix_password not found` | Vault not loaded        | Run with `--ask-vault-pass`          |
| `Environment variable not set`    | Missing env var         | Check `env \| grep WALLIX`           |

## 🔧 Troubleshooting

### Module Not Found

```bash
ansible-galaxy collection list | grep wallix
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection --force
```

### SSL Certificate Errors

```yaml
# Development only
validate_certs: false

# Production - add CA certificate to trust store
```

### Secret Checkout Failed

- Verify account exists on target device
- Check API user authorization for target
- Ensure correct format: `account@domain@device`
- Confirm account is not already checked out

## 🔒 Security Best Practices

### Playbook Security

```yaml
# Always use no_log for secret tasks
- name: Checkout secret
  wallix.pam.secret:
    # ...
  register: secret
  no_log: true

# Use block/always for guaranteed cleanup
- block:
    - name: Deploy with secret
      # ...
  always:
    - name: Remove temporary files
      ansible.builtin.file:
        path: /tmp/ssh_key
        state: absent
```

### Network Security

- Always use HTTPS for API connections
- Enable `validate_certs: true` in production
- Restrict API access by IP when possible
- Use dedicated service accounts with minimal permissions

## 📖 Documentation

- [Installation Guide](docs/installation.md)
- [Roles Reference](docs/roles.md)
- [GitLab + OpenShift Integration](docs/scenario_gitlab_openshift.md)
- [Examples](examples/)

## 🤝 Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines.

## Support

- **Documentation**: <https://github.com/wallix/Automation_Showroom/tree/main/Ansible/wallix-ansible-collection>
- **Issues**: <https://github.com/wallix/Automation_Showroom/issues>

## 📄 License

MPL-2.0 (Mozilla Public License 2.0) - See [LICENSE](../../LICENSE)
