# WALLIX Bastion - Ansible Become Plugin

Custom Ansible become plugin for WALLIX Bastion privilege escalation using the WABSuper mechanism.

## Overview

This plugin enables privilege escalation on WALLIX Bastion systems through a multi-hop escalation path:

```ini
wabadmin (SSH) → WABSuper wrapper → wabsuper → sudo (optional) → root
```

The plugin handles both single-step (to wabsuper) and dual-step (to root) privilege escalation by reading passwords from environment variables, avoiding stdin conflicts with Ansible's pipelining mechanism.

**Key Features:**

- Double escalation support: wabadmin → wabsuper → root
- Environment variable password passing (no stdin conflicts)
- Compatible with all Ansible modules
- Automatic detection of nested sudo requirements
- Full Ansible Vault support for secure password storage

## Why This Plugin Exists

WALLIX Bastion uses a unique privilege escalation process that does not work with Ansible's standard become plugin. Commands must be wrapped using `/bin/bash -c "command"`, and direct execution of binaries is not allowed. The official WABSuper wrapper manages this requirement, and our plugin connects it with Ansible to enable proper privilege escalation.

## Installation

### 1. Copy Files to Your Ansible Project

```bash
# Copy the become plugin
cp wallix_super.py /path/to/your/ansible/project/

# Copy the wrapper script
cp wabsuper-wrapper.py /path/to/your/ansible/project/
```

### 2. Deploy Wrapper to Bastion

You can manually copy and set permissions for the wrapper script, or automate this step using an Ansible playbook.

**Manual Deployment:**

```bash
# Copy wrapper to the bastion (adjust IP and port)
scp -P 2242 wabsuper-wrapper.py wabadmin@192.168.1.75:/tmp/

# Make it executable
ssh -p 2242 wabadmin@192.168.1.75 "chmod +x /tmp/wabsuper-wrapper.py"
```

**Automated Deployment with Ansible:**

Add a task to your playbook to copy and set permissions for the wrapper:

```yaml
- name: Deploy wabsuper-wrapper.py to bastion
    hosts: wallix_bastions
    tasks:
        - name: Copy wrapper script to /tmp
            copy:
                src: wabsuper-wrapper.py
                dest: /tmp/wabsuper-wrapper.py
                mode: '0755'
```

This ensures the wrapper is present and executable before privilege escalation tasks run.

### 3. Configure Ansible

Create or update `ansible.cfg`:

```ini
[defaults]
become_plugins = ./
pipelining = False  # REQUIRED: pipelining must be disabled

[privilege_escalation]
become_method = wallix_super
become_exe = /tmp/wabsuper-wrapper.py
become_user = wabsuper
```

## Quick Start Example

### Step 1: Create Ansible Vault for Credentials

Use the provided script to create an encrypted vault:

```bash
./create-vault.sh
```

This will:

1. Create `group_vars/wallix_bastion/` directory structure
2. Prompt for wabadmin SSH password
3. Prompt for wabsuper become password
4. Prompt for vault encryption password
5. Create encrypted `vault.yml` and unencrypted `vars.yml`

**Manual vault creation (alternative):**

```bash
# Create directory
mkdir -p group_vars/wallix_bastion

# Create encrypted vault
ansible-vault create group_vars/wallix_bastion/vault.yml
```

Add the following content:

```yaml
---
vault_wabadmin_password: "your_wabadmin_ssh_password"
vault_wabsuper_password: "your_wabsuper_become_password"
```

Create `group_vars/wallix_bastion/vars.yml`:

```yaml
---
ansible_password: "{{ vault_wabadmin_password }}"
ansible_become_password: "{{ vault_wabsuper_password }}"
```

### Step 2: Configure Inventory

Create or update `inventory.ini`:

```ini
[wallix_bastion]
wallix-bastion ansible_host=192.168.1.75 ansible_port=2242 ansible_user=wabadmin

[wallix_bastion:vars]
ansible_become_method=wallix_super
ansible_become_user=wabsuper
```

### Step 3: Run Example Playbook

The included `example_playbook.yml` demonstrates basic usage:

```bash
# Run with vault password prompt
ansible-playbook -i inventory.ini example_playbook.yml --ask-vault-pass

# Or with vault password file
ansible-playbook -i inventory.ini example_playbook.yml --vault-password-file ~/.vault_pass.txt
```

This playbook will:

1. Deploy the wrapper script to the bastion
2. Execute `WABVersion` to display bastion version
3. Execute `bastion-get-auth-statistics` to show authentication statistics

**Example output:**

```ini
PLAY [Deploy wrapper and execute WALLIX commands] ****************************

TASK [Copy wabsuper-wrapper.py to bastion] ***********************************
changed: [wallix-bastion]

TASK [Get WALLIX Bastion version] ********************************************
ok: [wallix-bastion]

TASK [Display WALLIX version] ************************************************
ok: [wallix-bastion] => {
        "msg": [
                "WALLIX Bastion 12.0.15"
        ]
}

TASK [Get bastion authentication statistics] *********************************
ok: [wallix-bastion]

TASK [Display authentication statistics] *************************************
ok: [wallix-bastion] => {
        "msg": [
                "{\"min\": 0, \"average\": 0.009190027546933956, \"max\": 1, \"peak_users\": [\"admin\"], \"peak_start_datetime\": \"2025-09-30 19:54:00+02:00\", \"peak_end_datetime\": \"2025-09-30 20:26:00+02:00\"}"
        ]
}

PLAY RECAP *******************************************************************
wallix-bastion             : ok=5    changed=1    unreachable=0    failed=0
```

## Configuration

```yaml
become_method = wallix_super
become_exe = /tmp/wabsuper-wrapper.py
become_user = wabsuper
```

### Basic Inventory Setup

**inventory.ini:**

```ini
[wallix_bastions]
wallix-bastion ansible_host=192.168.1.75 ansible_port=2242 ansible_user=wabadmin

[wallix_bastions:vars]
ansible_become_method=wallix_super
ansible_become_user=wabsuper # or 'root' for double escalation
```

### Secure Password Management with Ansible Vault

#### Step 1: Create encrypted vault file

```bash
# Create encrypted vault file for your bastion group
ansible-vault create group_vars/wallix_bastions/vault.yml
```

#### Step 2: Add passwords to vault

```yaml
# group_vars/wallix_bastions/vault.yml (encrypted)
---
vault_wabadmin_password: "your_wabadmin_ssh_password"
vault_wabsuper_password: "your_wabsuper_become_password"
```

#### Step 3: Reference vault variables

```yaml
# group_vars/wallix_bastions/vars.yml (unencrypted)
---
ansible_password: "{{ vault_wabadmin_password }}"
ansible_become_password: "{{ vault_wabsuper_password }}"
```

#### Step 4: Run playbooks with vault password

```bash
# Prompt for vault password
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass

# Or use a vault password file
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ~/.vault_pass.txt
```

#### Alternative: Using Vault ID (Recommended for Multiple Vaults)

```bash
# Create vault with specific ID
ansible-vault create --vault-id wallix@prompt group_vars/wallix_bastions/vault.yml

# Run playbook with vault ID
ansible-playbook -i inventory.ini playbook.yml --vault-id wallix@prompt
```

## Usage Examples

### Basic Playbook

```yaml
---
- name: Execute commands on WALLIX Bastion
    hosts: wallix_bastions
    become: yes

    tasks:
        - name: Check current user
            command: whoami
            register: result

        - name: Display result
            debug:
                msg: "Running as: {{ result.stdout }}"
```

### Escalate to wabsuper Only

```yaml
---
- name: Execute as wabsuper
    hosts: wallix_bastions
    become: yes
    become_user: wabsuper

    tasks:
        - name: Check wabsuper environment
            command: env
            register: env_output
```

### Escalate to root (Double Escalation)

```yaml
---
- name: Execute as root
    hosts: wallix_bastions
    become: yes
    become_user: root

    tasks:
        - name: Read system configuration
            command: cat /etc/shadow
            register: shadow_content
            no_log: true
```

### Mixed Escalation in Single Playbook

```yaml
---
- name: Mixed privilege levels
    hosts: wallix_bastions

    tasks:
        - name: Run as wabadmin (no escalation)
            command: whoami
            register: normal_user

        - name: Run as wabsuper
            command: whoami
            become: yes
            become_user: wabsuper
            register: super_user

        - name: Run as root
            command: whoami
            become: yes
            become_user: root
            register: root_user

        - name: Show all users
            debug:
                msg:
                    - "Normal: {{ normal_user.stdout }}"
                    - "Super: {{ super_user.stdout }}"
                    - "Root: {{ root_user.stdout }}"
```

## Command-Line Usage

### With Vault Password Prompt

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

### With Vault Password File

```bash
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ~/.vault_pass.txt
```

### With Manual Password Prompt (No Vault)

```bash
# Prompt for both SSH and become passwords
ansible-playbook -i inventory.ini playbook.yml --ask-pass --ask-become-pass
```

### Limit to Specific Hosts

```bash
ansible-playbook -i inventory.ini playbook.yml --limit wallix-bastion --ask-vault-pass
```

### Verbose Mode for Debugging

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass -vvv
```

## How It Works

### Escalation Paths

#### Path 1: wabadmin → wabsuper

When `become_user: wabsuper`:

```bash
/tmp/wabsuper-wrapper.py -c "command"
    → reads ANSIBLE_BECOME_PASS environment variable
    → calls: echo "$password" | sudo -u wabsuper -S /bin/bash -c "command"
```

#### Path 2: wabadmin → wabsuper → root

When `become_user: root`:

```bash
/tmp/wabsuper-wrapper.py -c "sudo -i command"
    → reads ANSIBLE_BECOME_PASS environment variable
    → calls: echo "$password" | sudo -u wabsuper -S /bin/bash -c "sudo -i command"
    → detects nested sudo and sends password again
```

#### Why Pipelining Must Be Disabled

Ansible's pipelining feature sends Python code directly via stdin, which conflicts with password input on stdin. Since our wrapper needs to send the password to sudo via stdin, pipelining must be disabled in `ansible.cfg`.

## Troubleshooting

### Authentication Failures

**Symptom:** "Sorry, try again" or "incorrect password"

**Solution:** Verify you're using the correct password:

- SSH authentication uses `ansible_password` (wabadmin password)
- Privilege escalation uses `ansible_become_password` (wabsuper password)

### Wrapper Not Found

**Symptom:** "No such file or directory: /tmp/wabsuper-wrapper.py"

**Solution:** Ensure the wrapper is copied to the bastion and executable:

```bash
scp -P 2242 wabsuper-wrapper.py wabadmin@192.168.1.75:/tmp/
ssh -p 2242 wabadmin@192.168.1.75 "chmod +x /tmp/wabsuper-wrapper.py"
```

### Connection Timeout

**Symptom:** SSH connection times out

**Solution:** Verify SSH connectivity and port:

```bash
ssh -p 2242 wabadmin@192.168.1.75
```

### Vault Decryption Errors

**Symptom:** "Decryption failed"

**Solution:** Verify vault password is correct:

```bash
ansible-vault view group_vars/wallix_bastions/vault.yml
```

### Debug Mode

Enable verbose output to see exact commands being executed:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass -vvvv
```

## Architecture Details

### Component Overview

```ini
┌─────────────────────────────────────────────────────────────┐
│ 1. Ansible Controller                                        │
│    - Reads vault-encrypted passwords                         │
│    - Sets ANSIBLE_BECOME_PASS environment variable           │
└─────────────────────────────────────────────────────────────┘
                                                     ↓ SSH
┌─────────────────────────────────────────────────────────────┐
│ 2. WALLIX Bastion (wabadmin user)                            │
│    - Receives command via wallix_super plugin                │
└─────────────────────────────────────────────────────────────┘
                                                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. wabsuper-wrapper.py                                       │
│    - Reads ANSIBLE_BECOME_PASS                               │
│    - Wraps command for WABSuper/sudo                         │
│    - Handles password passing via stdin                      │
└─────────────────────────────────────────────────────────────┘
                                                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. sudo -u wabsuper -S /bin/bash -c "command"                │
│    - Receives password from wrapper                          │
│    - Executes command as wabsuper                            │
└─────────────────────────────────────────────────────────────┘
                                                     ↓ (optional)
┌─────────────────────────────────────────────────────────────┐
│ 5. sudo -i (if become_user: root)                            │
│    - Receives same password again                            │
│    - Executes command as root                                │
└─────────────────────────────────────────────────────────────┘
```

### Why Native Ansible sudo Plugin Fails

The native sudo plugin attempts to execute commands like:

```bash
sudo -u wabsuper -S command
```

However, WALLIX Bastion's sudoers configuration allows:

```bash
sudo -u wabsuper -S /bin/bash -c command
```

Any attempt to execute other binaries (python, whoami, etc.) directly is rejected by sudoers, causing Ansible to hang indefinitely.

## Security Considerations

- **Use WALLIX AAPM:** Leverage the WALLIX application-to-application password management (AAPM) features for enhanced security
- **Use Ansible Vault:** Never store passwords in plain text
- **Separate Passwords:** Use different passwords for wabadmin (SSH) and wabsuper (become)
- **Vault Password Files:** Secure vault password files with appropriate permissions (0600)
- **Sensitive Tasks:** Use `no_log: true` for tasks handling sensitive data
- **Regular Rotation:** Rotate both SSH and become passwords regularly
- **SSH Keys:** Consider using SSH key authentication for wabadmin when possible

## Files

- `wallix_super.py` - Ansible become plugin
- `wabsuper-wrapper.py` - Wrapper script for password passing
- `create-vault.sh` - Helper script to create Ansible Vault with credentials
- `example_playbook.yml` - Example playbook demonstrating deployment and usage
- `ansible.cfg` - Example Ansible configuration
- `inventory.ini` - Example inventory file

## Compatibility

- Ansible 2.9+
- WALLIX Bastion 12.0+
- Python 3.6+

## Documentation

- **[WABSUPER_MODIFICATION.md](WIP/WABSUPER_MODIFICATION.md)** - Guide to modify WABSuper on bastion
- **[SUDO_DIRECT_ANALYSIS.md](WIP/SUDO_DIRECT_ANALYSIS.md)** - Analysis of direct sudo usage
- **[SUMMARY.md](WIP/SUMMARY.md)** - Quick summary of the solution

## Support

For issues specific to WALLIX Bastion configuration, consult the official WALLIX documentation or contact WALLIX support.
