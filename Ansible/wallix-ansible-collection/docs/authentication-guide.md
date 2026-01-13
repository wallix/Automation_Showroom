# WALLIX PAM Collection - Authentication Guide

## Overview

The WALLIX PAM Ansible Collection provides **flexible authentication** supporting multiple credential sources. Choose the method that best fits your environment:

- **Ansible Vault** - Recommended for production
- **Plain Variables** - Suitable for development/testing  
- **Environment Variables** - Ideal for CI/CD pipelines

All methods support automatic fallback, allowing seamless transitions between environments.

---

## Credential Priority Chain

The collection automatically checks credentials in this order:

```text
1. Plain variables (wallix_username, wallix_password)
   ↓ (if not defined)
2. Vault variables (vault_wallix_username, vault_wallix_password)
   ↓ (if not defined)
3. Environment variables (WALLIX_API_USER, WALLIX_API_PASSWORD)
   ↓ (if not defined)
4. Default values (admin / empty)
```

This allows you to override credentials at any level without changing playbooks.

---

## Method 1: Ansible Vault (Production)

### ✅ Best for

- Production environments
- Shared repositories
- Team collaboration
- Secure credential storage

### Setup Steps

#### 1. Create Vault File

```bash
# Create encrypted vault
ansible-vault create group_vars/all/vault.yml
```

Enter vault password when prompted.

#### 2. Add Credentials to Vault

```yaml
# group_vars/all/vault.yml (encrypted)
---
vault_wallix_username: "api-admin"
vault_wallix_password: "SecureP@ssw0rd!"

# Optional: API Key authentication
vault_api_key: "your-api-key-here"
vault_api_secret: "your-api-secret-here"
```

#### 3. Reference in Configuration

```yaml
# group_vars/all/vars.yml (unencrypted)
---
wallix_bastion_host: "bastion.company.com"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

wallix_auth:
  initial_auth_method: "credentials"
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
  connection:
    verify_ssl: true
    timeout: 30
```

#### 4. Run Playbook with Vault

```bash
# Option A: Prompt for vault password
ansible-playbook playbook.yml --ask-vault-pass

# Option B: Use password file
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Option C: Use environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook playbook.yml
```

### Vault Best Practices

✅ **DO:**

- Store vault password securely (password manager, secrets management system)
- Use different vaults for different environments (dev/staging/prod)
- Add `*.vault.yml` to `.gitignore` if using separate vault files
- Rotate vault passwords periodically
- Use vault IDs for multiple vaults:

  ```bash
  ansible-vault create --vault-id prod@prompt group_vars/prod/vault.yml
  ansible-playbook playbook.yml --vault-id prod@prompt
  ```

❌ **DON'T:**

- Commit unencrypted vault password files
- Share vault passwords via email/chat
- Use the same vault password across all environments
- Store vault password in shell history

---

## Method 2: Plain Variables (Development)

### ✅ Best for

- Local development
- Testing playbooks
- Quick prototyping
- Non-sensitive environments

### Setup Steps

#### 1. Define in Variables File

```yaml
# group_vars/all.yml
---
wallix_bastion_host: "bastion-dev.local"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

# Plain credentials (no vault)
wallix_username: "test-user"
wallix_password: "test-password"

wallix_auth:
  initial_auth_method: "credentials"
  connection:
    verify_ssl: false  # OK for local dev
    timeout: 30
```

#### 2. Run Playbook Normally

```bash
ansible-playbook playbook.yml
```

The collection automatically uses `wallix_username` and `wallix_password` if `vault_*` variables are not defined.

### ⚠️ Security Warnings

- **NEVER** use plain variables in production
- **NEVER** commit credentials to version control
- Add credentials files to `.gitignore`:

  ```gitignore
  # .gitignore
  **/vars/credentials.yml
  **/group_vars/*/credentials.yml
  local_vars.yml
  ```

### Safe Development Pattern

```yaml
# group_vars/all.yml (committed to repo)
---
wallix_bastion_host: "bastion-dev.local"
wallix_auth:
  connection:
    verify_ssl: false

# vars/credentials.yml (in .gitignore, never committed)
---
wallix_username: "test-user"
wallix_password: "test-password"
```

```yaml
# playbook.yml
---
- hosts: localhost
  vars_files:
    - vars/credentials.yml  # Not in repo
  roles:
    - wallix.pam.wallix-auth
```

---

## Method 3: Environment Variables (CI/CD)

### ✅ Best for

- CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins)
- Docker containers
- Cloud environments
- Automated deployments

### Setup Steps

#### 1. Set Environment Variables

```bash
# Required variables
export WALLIX_API_USER="ci-automation-user"
export WALLIX_API_PASSWORD="pipeline-secure-password"

# Optional variables
export WALLIX_API_KEY="optional-api-key"
export WALLIX_API_SECRET="optional-api-secret"

# Run playbook
ansible-playbook playbook.yml
```

#### 2. Minimal Playbook Configuration

```yaml
# playbook.yml
---
- hosts: localhost
  vars:
    wallix_bastion_host: "bastion.company.com"
    # No credentials needed - auto-detected from environment
  roles:
    - wallix.pam.wallix-auth
    - wallix.pam.wallix-devices
```

The collection automatically falls back to environment variables when no other credentials are defined.

### CI/CD Integration Examples

#### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to WALLIX

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Ansible
        run: pip install ansible
      
      - name: Run WALLIX Provisioning
        env:
          WALLIX_API_USER: ${{ secrets.WALLIX_USER }}
          WALLIX_API_PASSWORD: ${{ secrets.WALLIX_PASSWORD }}
        run: |
          ansible-playbook playbook.yml
```

#### GitLab CI

```yaml
# .gitlab-ci.yml
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
    agent any
    
    environment {
        WALLIX_API_USER = credentials('wallix-user')
        WALLIX_API_PASSWORD = credentials('wallix-password')
    }
    
    stages {
        stage('Deploy') {
            steps {
                sh 'ansible-playbook playbook.yml'
            }
        }
    }
}
```

#### Docker Compose

```yaml
# docker-compose.yml
version: '3'
services:
  ansible:
    image: ansible/ansible:latest
    environment:
      - WALLIX_API_USER=${WALLIX_USER}
      - WALLIX_API_PASSWORD=${WALLIX_PASSWORD}
    volumes:
      - ./playbooks:/playbooks
    command: ansible-playbook /playbooks/playbook.yml
```

```bash
# Run with environment file
docker-compose --env-file .env up
```

---

## Authentication Methods

### Username/Password Authentication

Default authentication method using basic auth credentials.

```yaml
wallix_auth:
  initial_auth_method: "credentials"
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
```

**Variables:**

- Plain: `wallix_username`, `wallix_password`
- Vault: `vault_wallix_username`, `vault_wallix_password`
- Environment: `WALLIX_API_USER`, `WALLIX_API_PASSWORD`

### API Key Authentication

Alternative method using API keys (if your WALLIX instance supports it).

```yaml
wallix_auth:
  initial_auth_method: "api_key"
  api_key:
    key: "{{ vault_api_key }}"
    secret: "{{ vault_api_secret }}"
```

**Variables:**

- Plain: `wallix_api_key`, `wallix_api_secret`
- Vault: `vault_api_key`, `vault_api_secret`
- Environment: `WALLIX_API_KEY`, `WALLIX_API_SECRET`

---

## Mixing Methods (Advanced)

You can mix credential methods across environments:

```yaml
# group_vars/all.yml (base configuration)
wallix_bastion_host: "bastion.company.com"

# group_vars/production/vault.yml (vault for prod)
vault_wallix_username: "prod-api-user"
vault_wallix_password: "prod-password"

# group_vars/development/vars.yml (plain vars for dev)
wallix_username: "dev-user"
wallix_password: "dev-password"

# CI/CD pipeline uses environment variables
# (no group_vars needed)
```

Ansible automatically picks the right credentials based on the inventory group.

---

## Validation & Troubleshooting

### Verify Credentials

Test authentication without running full playbook:

```bash
# Test with curl
curl -k -u "username:password" \
  https://bastion.company.com/api/version

# Test with Ansible ad-hoc
ansible localhost -m debug -a "var=wallix_password"
```

### Debug Credential Resolution

Enable debug mode to see which credential source is used:

```yaml
wallix_debug:
  enabled: true
  log_requests: true
```

### Common Issues

| Issue                             | Cause                   | Solution                             |
| --------------------------------- | ----------------------- | ------------------------------------ |
| `password is undefined`           | No credentials provided | Set at least one credential method   |
| `Authentication failed`           | Wrong credentials       | Verify username/password are correct |
| `vault_wallix_password not found` | Vault not loaded        | Run with `--ask-vault-pass`          |
| `Environment variable not set`    | Missing env var         | Check `env \| grep WALLIX`           |

### Testing Credential Priority

```yaml
# Test which credential is being used
- name: Show resolved credentials
  debug:
    msg:
      - "Username: {{ wallix_auth.credentials.username }}"
      - "Password length: {{ wallix_auth.credentials.password | length }}"
```

---

## Security Best Practices

### General Guidelines

✅ **Always:**

- Use vault for production environments
- Rotate credentials regularly
- Use different credentials per environment
- Enable SSL verification in production (`verify_ssl: true`)
- Use `no_log: true` for tasks handling credentials
- Limit API user permissions to minimum required

❌ **Never:**

- Commit plain-text passwords to version control
- Share credentials via insecure channels
- Use the same password across environments
- Disable SSL verification in production
- Log credentials in playbook output
- Use default passwords

### Least Privilege

Create dedicated API users with minimal permissions:

```yaml
# Good: Dedicated API user with limited permissions
wallix_username: "ansible-api-readonly"

# Bad: Using admin account
wallix_username: "admin"
```

### Credential Rotation

Implement regular credential rotation:

1. Generate new credentials in WALLIX
2. Update vault file with new credentials
3. Test with new credentials
4. Remove old credentials
5. Update vault password

```bash
# Rotate vault credentials
ansible-vault rekey group_vars/all/vault.yml
```

---

## Migration Guide

### From Hardcoded to Vault

```yaml
# Before (hardcoded)
wallix_auth:
  credentials:
    username: "admin"
    password: "hardcoded-password"

# After (vault)
wallix_auth:
  credentials:
    username: "{{ vault_wallix_username }}"
    password: "{{ vault_wallix_password }}"
```

### From Plain to Environment Variables

```yaml
# Before (plain variables)
wallix_username: "user"
wallix_password: "password"

# After (remove from playbook, set in environment)
# No changes needed in playbook!
# Collection automatically uses environment variables
```

```bash
export WALLIX_API_USER="user"
export WALLIX_API_PASSWORD="password"
```

---

## Quick Reference

### Variable Names

| Type        | Username                | Password                | API Key          | API Secret          |
| ----------- | ----------------------- | ----------------------- | ---------------- | ------------------- |
| Plain       | `wallix_username`       | `wallix_password`       | `wallix_api_key` | `wallix_api_secret` |
| Vault       | `vault_wallix_username` | `vault_wallix_password` | `vault_api_key`  | `vault_api_secret`  |
| Environment | `WALLIX_API_USER`       | `WALLIX_API_PASSWORD`   | `WALLIX_API_KEY` | `WALLIX_API_SECRET` |

### Commands Cheat Sheet

```bash
# Create vault
ansible-vault create group_vars/all/vault.yml

# Edit vault
ansible-vault edit group_vars/all/vault.yml

# Change vault password
ansible-vault rekey group_vars/all/vault.yml

# View vault content
ansible-vault view group_vars/all/vault.yml

# Run with vault
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Run with environment
WALLIX_API_USER=user WALLIX_API_PASSWORD=pass ansible-playbook playbook.yml
```

---

## Support

For issues or questions:

- GitHub Issues: <https://github.com/wallix/Automation_Showroom/issues>
- Documentation: <https://github.com/wallix/Automation_Showroom/tree/main/Ansible/wallix-ansible-collection>
