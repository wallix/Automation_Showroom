# WALLIX PAM Ansible Collection















































































































































































































































































































































































































































































































































































- Documentation: https://github.com/wallix/Automation_Showroom/tree/main/Ansible/wallix-ansible-collection- GitHub Issues: https://github.com/wallix/Automation_Showroom/issuesFor issues or questions:## Support---```WALLIX_API_USER=user WALLIX_API_PASSWORD=pass ansible-playbook playbook.yml# Run with environmentansible-playbook playbook.yml --vault-password-file ~/.vault_passansible-playbook playbook.yml --ask-vault-pass# Run with vaultansible-vault view group_vars/all/vault.yml# View vault contentansible-vault rekey group_vars/all/vault.yml# Change vault passwordansible-vault edit group_vars/all/vault.yml# Edit vaultansible-vault create group_vars/all/vault.yml# Create vault```bash### Commands Cheat Sheet| Environment | `WALLIX_API_USER` | `WALLIX_API_PASSWORD` | `WALLIX_API_KEY` | `WALLIX_API_SECRET` || Vault | `vault_wallix_username` | `vault_wallix_password` | `vault_api_key` | `vault_api_secret` || Plain | `wallix_username` | `wallix_password` | `wallix_api_key` | `wallix_api_secret` ||------|----------|----------|---------|------------|| Type | Username | Password | API Key | API Secret |### Variable Names## Quick Reference---```export WALLIX_API_PASSWORD="password"export WALLIX_API_USER="user"```bash```# Collection automatically uses environment variables# No changes needed in playbook!# After (remove from playbook, set in environment)wallix_password: "password"wallix_username: "user"# Before (plain variables)```yaml### From Plain to Environment Variables```    password: "{{ vault_wallix_password }}"    username: "{{ vault_wallix_username }}"  credentials:wallix_auth:# After (vault)    password: "hardcoded-password"    username: "admin"  credentials:wallix_auth:# Before (hardcoded)```yaml### From Hardcoded to Vault## Migration Guide---```ansible-vault rekey group_vars/all/vault.yml# Rotate vault credentials```bash5. Update vault password4. Remove old credentials3. Test with new credentials2. Update vault file with new credentials1. Generate new credentials in WALLIXImplement regular credential rotation:### Credential Rotation```wallix_username: "admin"# Bad: Using admin accountwallix_username: "ansible-api-readonly"# Good: Dedicated API user with limited permissions```yamlCreate dedicated API users with minimal permissions:### Least Privilege- Use default passwords- Log credentials in playbook output- Disable SSL verification in production- Use the same password across environments- Share credentials via insecure channels- Commit plain-text passwords to version control❌ **Never:**- Limit API user permissions to minimum required- Use `no_log: true` for tasks handling credentials- Enable SSL verification in production (`verify_ssl: true`)- Use different credentials per environment- Rotate credentials regularly- Use vault for production environments✅ **Always:**### General Guidelines## Security Best Practices---```      - "Password length: {{ wallix_auth.credentials.password | length }}"      - "Username: {{ wallix_auth.credentials.username }}"    msg:  debug:- name: Show resolved credentials# Test which credential is being used```yaml### Testing Credential Priority| `Environment variable not set` | Missing env var | Check `env \| grep WALLIX` || `vault_wallix_password not found` | Vault not loaded | Run with `--ask-vault-pass` || `Authentication failed` | Wrong credentials | Verify username/password are correct || `password is undefined` | No credentials provided | Set at least one credential method ||-------|-------|----------|| Issue | Cause | Solution |### Common Issues```  log_requests: true  enabled: truewallix_debug:```yamlEnable debug mode to see which credential source is used:### Debug Credential Resolution```ansible localhost -m debug -a "var=wallix_password"# Test with Ansible ad-hoc  https://bastion.company.com/api/versioncurl -k -u "username:password" \# Test with curl```bashTest authentication without running full playbook:### Verify Credentials## Validation & Troubleshooting---Ansible automatically picks the right credentials based on the inventory group.```# (no group_vars needed)# CI/CD pipeline uses environment variableswallix_password: "dev-password"wallix_username: "dev-user"# group_vars/development/vars.yml (plain vars for dev)vault_wallix_password: "prod-password"vault_wallix_username: "prod-api-user"# group_vars/production/vault.yml (vault for prod)wallix_bastion_host: "bastion.company.com"# group_vars/all.yml (base configuration)```yamlYou can mix credential methods across environments:## Mixing Methods (Advanced)---- Environment: `WALLIX_API_KEY`, `WALLIX_API_SECRET`- Vault: `vault_api_key`, `vault_api_secret`- Plain: `wallix_api_key`, `wallix_api_secret`**Variables:**```    secret: "{{ vault_api_secret }}"    key: "{{ vault_api_key }}"  api_key:  initial_auth_method: "api_key"wallix_auth:```yamlAlternative method using API keys (if your WALLIX instance supports it).### API Key Authentication- Environment: `WALLIX_API_USER`, `WALLIX_API_PASSWORD`- Vault: `vault_wallix_username`, `vault_wallix_password`- Plain: `wallix_username`, `wallix_password`**Variables:**```    password: "{{ vault_wallix_password }}"    username: "{{ vault_wallix_username }}"  credentials:  initial_auth_method: "credentials"wallix_auth:```yamlDefault authentication method using basic auth credentials.### Username/Password Authentication## Authentication Methods---```docker-compose --env-file .env up# Run with environment file```bash```    command: ansible-playbook /playbooks/playbook.yml      - ./playbooks:/playbooks    volumes:      - WALLIX_API_PASSWORD=${WALLIX_PASSWORD}      - WALLIX_API_USER=${WALLIX_USER}    environment:    image: ansible/ansible:latest  ansible:services:version: '3'# docker-compose.yml```yaml#### Docker Compose```}    }        }            }                sh 'ansible-playbook playbook.yml'            steps {        stage('Deploy') {    stages {        }        WALLIX_API_PASSWORD = credentials('wallix-password')        WALLIX_API_USER = credentials('wallix-user')    environment {        agent anypipeline {```groovy#### Jenkins Pipeline```    WALLIX_API_PASSWORD: $WALLIX_PASSWORD    WALLIX_API_USER: $WALLIX_USER  variables:    - ansible-playbook playbook.yml  script:    - pip install ansible  before_script:  image: python:3.11  stage: deploydeploy:# .gitlab-ci.yml```yaml#### GitLab CI```          ansible-playbook playbook.yml        run: |          WALLIX_API_PASSWORD: ${{ secrets.WALLIX_PASSWORD }}          WALLIX_API_USER: ${{ secrets.WALLIX_USER }}        env:      - name: Run WALLIX Provisioning              run: pip install ansible      - name: Install Ansible            - uses: actions/checkout@v3    steps:    runs-on: ubuntu-latest  deploy:jobs:on: [push]name: Deploy to WALLIX# .github/workflows/deploy.yml```yaml#### GitHub Actions### CI/CD Integration ExamplesThe collection automatically falls back to environment variables when no other credentials are defined.```    - wallix.pam.wallix-devices    - wallix.pam.wallix-auth  roles:    # No credentials needed - auto-detected from environment    wallix_bastion_host: "bastion.company.com"  vars:- hosts: localhost---# playbook.yml```yaml#### 2. Minimal Playbook Configuration```ansible-playbook playbook.yml# Run playbookexport WALLIX_API_SECRET="optional-api-secret"export WALLIX_API_KEY="optional-api-key"# Optional variablesexport WALLIX_API_PASSWORD="pipeline-secure-password"export WALLIX_API_USER="ci-automation-user"# Required variables```bash#### 1. Set Environment Variables### Setup Steps- Automated deployments- Cloud environments- Docker containers- CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins)### ✅ Best for:## Method 3: Environment Variables (CI/CD)---```    - wallix.pam.wallix-auth  roles:    - vars/credentials.yml  # Not in repo  vars_files:- hosts: localhost---# playbook.yml```yaml```wallix_password: "test-password"wallix_username: "test-user"---# vars/credentials.yml (in .gitignore, never committed)    verify_ssl: false  connection:wallix_auth:wallix_bastion_host: "bastion-dev.local"---# group_vars/all.yml (committed to repo)```yaml### Safe Development Pattern  ```  local_vars.yml  **/group_vars/*/credentials.yml  **/vars/credentials.yml  # .gitignore  ```gitignore- Add credentials files to `.gitignore`:- **NEVER** commit credentials to version control- **NEVER** use plain variables in production### ⚠️ Security WarningsThe collection automatically uses `wallix_username` and `wallix_password` if `vault_*` variables are not defined.```ansible-playbook playbook.yml```bash#### 2. Run Playbook Normally```    timeout: 30    verify_ssl: false  # OK for local dev  connection:  initial_auth_method: "credentials"wallix_auth:wallix_password: "test-password"wallix_username: "test-user"# Plain credentials (no vault)wallix_bastion_protocol: "https"wallix_bastion_port: 443wallix_bastion_host: "bastion-dev.local"---# group_vars/all.yml```yaml#### 1. Define in Variables File### Setup Steps- Non-sensitive environments- Quick prototyping- Testing playbooks- Local development### ✅ Best for:## Method 2: Plain Variables (Development)---- Store vault password in shell history- Use the same vault password across all environments- Share vault passwords via email/chat- Commit unencrypted vault password files❌ **DON'T:**  ```  ansible-playbook playbook.yml --vault-id prod@prompt  ansible-vault create --vault-id prod@prompt group_vars/prod/vault.yml  ```bash- Use vault IDs for multiple vaults:- Rotate vault passwords periodically- Add `*.vault.yml` to `.gitignore` if using separate vault files- Use different vaults for different environments (dev/staging/prod)- Store vault password securely (password manager, secrets management system)✅ **DO:**### Vault Best Practices```ansible-playbook playbook.ymlexport ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass# Option C: Use environment variableansible-playbook playbook.yml --vault-password-file ~/.vault_pass# Option B: Use password fileansible-playbook playbook.yml --ask-vault-pass# Option A: Prompt for vault password```bash#### 4. Run Playbook with Vault```    timeout: 30    verify_ssl: true  connection:    password: "{{ vault_wallix_password }}"    username: "{{ vault_wallix_username }}"  credentials:  initial_auth_method: "credentials"wallix_auth:wallix_bastion_protocol: "https"wallix_bastion_port: 443wallix_bastion_host: "bastion.company.com"---# group_vars/all/vars.yml (unencrypted)```yaml#### 3. Reference in Configuration```vault_api_secret: "your-api-secret-here"vault_api_key: "your-api-key-here"# Optional: API Key authenticationvault_wallix_password: "SecureP@ssw0rd!"vault_wallix_username: "api-admin"---# group_vars/all/vault.yml (encrypted)```yaml#### 2. Add Credentials to VaultEnter vault password when prompted.```ansible-vault create group_vars/all/vault.yml# Create encrypted vault```bash#### 1. Create Vault File### Setup Steps- Secure credential storage- Team collaboration- Shared repositories- Production environments### ✅ Best for:## Method 1: Ansible Vault (Production)---This allows you to override credentials at any level without changing playbooks.```4. Default values (admin / empty)   ↓ (if not defined)3. Environment variables (WALLIX_API_USER, WALLIX_API_PASSWORD)   ↓ (if not defined)2. Vault variables (vault_wallix_username, vault_wallix_password)   ↓ (if not defined)1. Plain variables (wallix_username, wallix_password)```The collection automatically checks credentials in this order:## Credential Priority Chain---All methods support automatic fallback, allowing seamless transitions between environments.- **Environment Variables** - Ideal for CI/CD pipelines- **Plain Variables** - Suitable for development/testing- **Ansible Vault** - Recommended for productionThe WALLIX PAM Ansible Collection provides **flexible authentication** supporting multiple credential sources. Choose the method that best fits your environment:## Overview[![Ansible Collection](https://img.shields.io/badge/Ansible-Collection-blue?logo=ansible)](https://github.com/wallix/Automation_Showroom)
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
  - **[Authentication Guide](docs/authentication-guide.md)** - Comprehensive credential configuration guide
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Contributing](#contributing)
- [License](#license)

## Overview

The `wallix.pam` collection provides a complete toolkit for automating WALLIX Bastion operations:

- **Provisioning**: Automate device, user, and authorization setup
- **Secret Management**: Securely retrieve passwords and SSH keys at runtime
- **Configuration**: Manage system settings, policies, and timeframes
- **Cleanup**: Safe resource removal with backup capabilities

## ✨ Features

| Category | Capabilities |
|----------|-------------|
| **Authentication** | API credentials, API keys, session management, cookie-based auth |
| **Infrastructure** | Devices, services, local accounts, global domains |
| **Access Control** | Users, user groups, authorizations, target groups |
| **Secrets** | Password/SSH key checkout, checkin, extend operations |
| **Policies** | Connection policies, timeframes, access rules |
| **Maintenance** | Cleanup, backups, configuration management |

## 📦 Requirements

| Component | Version |
|-----------|---------|
| Ansible Core | ≥ 2.15 |
| Python | ≥ 3.9 |
| WALLIX Bastion | ≥ 10.0 |
| `requests` library | Latest |

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
      no_log: true  # Always hide secrets!

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

| Module | Description |
|--------|-------------|
| `wallix.pam.secret` | Retrieve, checkout, checkin, and extend secrets from WALLIX Bastion |

### Lookup Plugins

| Plugin | Description |
|--------|-------------|
| `wallix.pam.secret` | Inline secret retrieval using `account@domain@device` format |

### Roles

| Role | Description |
|------|-------------|
| `wallix-auth` | API authentication and session management |
| `wallix-devices` | Device and service configuration |
| `wallix-users` | User and user group management |
| `wallix-authorizations` | Authorization and target group management |
| `wallix-global-domains` | Global domain (LDAP/AD) configuration |
| `wallix-global-accounts` | Global account management |
| `wallix-domains` | Domain-specific authentication |
| `wallix-timeframes` | Timeframe definitions for scheduled access |
| `wallix-connection-policies` | Connection policy management |
| `wallix-policies` | Generic policy management |
| `wallix-applications` | Application integration management |
| `wallix-config` | Bastion system configuration |
| `wallix-cleanup` | Safe resource cleanup with backup |

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
    # Format: account@domain@device
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

| Variable | Description |
|----------|-------------|
| `WALLIX_URL` | Bastion API URL (e.g., `https://bastion.example.com`) |
| `WALLIX_USER` | API username |
| `WALLIX_PASSWORD` | API password |
| `WALLIX_API_KEY` | API key (alternative to password) |

## ⚙️ Configuration Reference

### Authentication Configuration

The collection supports **three methods** for providing credentials, with automatic fallback:

#### Method 1: Ansible Vault (Recommended for Production)

```yaml
# Create encrypted vault file
# ansible-vault create group_vars/all/vault.yml

# group_vars/all/vault.yml (encrypted)
vault_wallix_username: "api-user"
vault_wallix_password: "secure-password"
vault_api_key: "optional-api-key"
vault_api_secret: "optional-api-secret"

# group_vars/all/vars.yml (unencrypted)
wallix_bastion_host: "bastion.example.com"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

wallix_auth:
  initial_auth_method: "credentials"  # or "api_key"
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
  session:
    use_cookie: true
    cleanup_on_exit: true
  connection:
    verify_ssl: true
    timeout: 30
    retry_count: 3
```

**Run with vault:**
```bash
ansible-playbook playbook.yml --ask-vault-pass
# or
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

#### Method 2: Plain Variables (Development/Testing)

```yaml
# group_vars/all.yml or vars/credentials.yml
wallix_bastion_host: "bastion.example.com"
wallix_username: "api-user"           # Plain variable
wallix_password: "test-password"      # Plain variable (NOT for production!)

wallix_auth:
  initial_auth_method: "credentials"
  # Credentials will auto-fallback to wallix_username/wallix_password
  # if vault_* variables are not defined
```

**⚠️ Warning:** Only use plain variables for development/testing. Never commit passwords to version control!

#### Method 3: Environment Variables (CI/CD Pipelines)

```bash
# Set environment variables
export WALLIX_API_USER="api-user"
export WALLIX_API_PASSWORD="secure-password"
export WALLIX_API_KEY="optional-api-key"
export WALLIX_API_SECRET="optional-api-secret"

# Run playbook - credentials auto-detected from environment
ansible-playbook playbook.yml
```

```yaml
# playbook.yml - no credentials needed in playbook
wallix_bastion_host: "bastion.example.com"
wallix_auth:
  initial_auth_method: "credentials"
  # Automatically uses environment variables as fallback
```

### Credential Priority Order

The collection checks credentials in this order:

1. **Plain variables**: `wallix_username`, `wallix_password`, `wallix_api_key`, `wallix_api_secret`
2. **Vault variables**: `vault_wallix_username`, `vault_wallix_password`, `vault_api_key`, `vault_api_secret`
3. **Environment variables**: `WALLIX_API_USER`, `WALLIX_API_PASSWORD`, `WALLIX_API_KEY`, `WALLIX_API_SECRET`
4. **Defaults**: `admin` / empty

### Core Configuration Variables

```yaml
# Connection settings
wallix_bastion_host: "bastion.example.com"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

# Authentication configuration
wallix_auth:
  # Auth method: "credentials" or "api_key"
  initial_auth_method: "credentials"
  
  # Credentials (username/password)
  credentials:
    username: "{{ vault_wallix_username }}"  # Auto-fallback enabled
    password: "{{ vault_wallix_password }}"  # Auto-fallback enabled
  
  # API Key (alternative to credentials)
  api_key:
    key: "{{ vault_api_key }}"               # Auto-fallback enabled
    secret: "{{ vault_api_secret }}"         # Auto-fallback enabled
  
  # Session management
  session:
    use_cookie: true
    auto_renew: true
    max_session_duration: 3600
    cleanup_on_exit: true
  
  # Connection settings
  connection:
    verify_ssl: true
    timeout: 30
    retry_count: 3
    retry_delay: 5

# API endpoint configuration
wallix_api:
  base_url: "{{ wallix_bastion_protocol }}://{{ wallix_bastion_host }}:{{ wallix_bastion_port }}/api"
```

## 🔧 Troubleshooting

### Common Issues

#### Authentication Errors

```bash
# Verify API credentials
curl -k -u "user:pass" https://bastion.example.com/api/accounts
```

#### SSL Certificate Errors

```yaml
# Development only - disable certificate validation
validate_certs: false

# Production - add CA certificate to trust store
```

#### Module Not Found

```bash
# Verify collection installation
ansible-galaxy collection list | grep wallix

# Reinstall collection
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection --force
```

#### Secret Checkout Failed

- Verify account exists on the target device
- Check API user authorization for the target
- Ensure correct format: `account@domain@device`
- Confirm account is not already checked out

## 🔒 Security Best Practices

### Credential Management

```yaml
# ✅ Use Ansible Vault for sensitive variables
wallix_auth:
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"

# ✅ Use environment variables in CI/CD
wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
```

### Playbook Security

```yaml
# ✅ Always use no_log for secret tasks
- name: Checkout secret
  wallix.pam.secret:
    # ...
  register: secret
  no_log: true  # Prevents secrets in logs

# ✅ Use block/always for guaranteed cleanup
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

- [Installation Guide](docs/installation.md) - Detailed installation options
- [Roles Reference](docs/roles.md) - Complete role documentation
- [GitLab + OpenShift Integration](docs/scenario_gitlab_openshift.md) - CI/CD workflow example
- [Examples](examples/) - Ready-to-use playbook templates

## 🤝 Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines.

## 📄 License

MPL-2.0 (Mozilla Public License 2.0) - See [LICENSE](../../LICENSE)
