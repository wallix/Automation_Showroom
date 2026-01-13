# WALLIX PAM Ansible Collection - Examples

This directory contains ready-to-use playbook templates and examples for the WALLIX PAM Ansible Collection.

## 📁 Contents

| File | Description |
|------|-------------|
| `template_playbook.yml` | Complete demo playbook showing checkout, usage, and checkin workflow |

## 🚀 Quick Start

### 1. Install the Collection

```bash
ansible-galaxy collection install git+https://github.com/wallix/Automation_Showroom.git#/Ansible/wallix-ansible-collection
```

### 2. Configure Credentials

The collection supports **three credential methods** with automatic fallback. Choose what fits your workflow:

**Option A: Ansible Vault (Recommended for Production)**

```bash
# Create encrypted vault file
ansible-vault create group_vars/all/vault.yml
```

Add to vault:
```yaml
vault_wallix_username: "api-user"
vault_wallix_password: "your-password"
```

**Option B: Environment Variables (Recommended for CI/CD)**

```bash
export WALLIX_API_USER="api-user"
export WALLIX_API_PASSWORD="your-password"
```

**Option C: Plain Variables (Development/Testing Only)**

```yaml
# vars/credentials.yml (add to .gitignore!)
wallix_username: "test-user"
wallix_password: "test-password"
```

**📖 Detailed Guide:** See [docs/authentication-guide.md](../docs/authentication-guide.md) for complete authentication documentation.

**Priority Order:** Plain variables → Vault variables → Environment variables → Defaults

### 3. Customize the Template

Edit `template_playbook.yml` and update the target account details:

```yaml
target_account: "root"          # Account name in WALLIX
target_domain: "local"          # Domain (local, AD domain, etc.)
target_device: "my-server"      # Device name as configured in WALLIX
```

### 4. Run the Playbook

```bash
# With environment variables
ansible-playbook template_playbook.yml

# With vault
ansible-playbook template_playbook.yml --ask-vault-pass
```

## 📋 Example Scenarios

### Scenario 1: SSH Key Checkout for Deployment

```yaml
- name: Deploy application with WALLIX-managed SSH key
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Checkout SSH key
      wallix.pam.secret:
        wallix_url: "{{ lookup('env', 'WALLIX_URL') }}"
        username: "{{ lookup('env', 'WALLIX_USER') }}"
        password: "{{ lookup('env', 'WALLIX_PASSWORD') }}"
        account: "deploy"
        domain: "local"
        device: "production-server"
        state: checkout
        validate_certs: true
      register: ssh_key
      no_log: true

    - name: Save SSH key temporarily
      ansible.builtin.copy:
        content: "{{ ssh_key.ssh_key }}"
        dest: /tmp/deploy_key
        mode: '0600'
      no_log: true

    - name: Deploy application
      ansible.builtin.command: /path/to/deploy.sh
      environment:
        SSH_KEY_FILE: /tmp/deploy_key

  always:
    - name: Remove temporary key
      ansible.builtin.file:
        path: /tmp/deploy_key
        state: absent
```

### Scenario 2: Database Password for Configuration

```yaml
- name: Configure application with database credentials
  hosts: webservers
  
  tasks:
    - name: Deploy database configuration
      ansible.builtin.template:
        src: db_config.j2
        dest: /etc/app/database.yml
        mode: '0600'
      vars:
        db_password: "{{ lookup('wallix.pam.secret', 'dbadmin@local@db-server-01') }}"
      no_log: true
```

### Scenario 3: Using Roles for Full Provisioning

```yaml
- name: Provision WALLIX Bastion
  hosts: bastion
  gather_facts: false
  
  vars_files:
    - vars/devices.yml
    - vars/users.yml
    - vars/authorizations.yml
  
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-devices
    - role: wallix.pam.wallix-global-domains
    - role: wallix.pam.wallix-users
    - role: wallix.pam.wallix-authorizations
    - role: wallix.pam.wallix-timeframes
```

## 🔒 Security Notes

1. **Always use `no_log: true`** on tasks that handle secrets
2. **Never commit credentials** to version control
3. **Use Ansible Vault** for stored credentials
4. **Clean up temporary files** in `always` blocks
5. **Enable SSL verification** in production (`validate_certs: true`)

## 📖 More Information

- [Main README](../README.md) - Full collection documentation
- [Installation Guide](../docs/installation.md) - Detailed installation options
- [GitLab + OpenShift Integration](../docs/scenario_gitlab_openshift.md) - CI/CD workflow
