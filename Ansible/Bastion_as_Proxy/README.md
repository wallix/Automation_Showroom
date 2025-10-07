# Using WALLIX Bastion as SSH Proxy

This example demonstrates how to use a WALLIX Bastion as an SSH proxy (jump host) to connect to remote machines.

## Overview

Instead of connecting directly to target servers, traffic is routed through the WALLIX Bastion using its built-in proxy mechanism:

```ini
Ansible Controller → WALLIX Bastion (Proxy) → Target Server
```

**WALLIX Proxy Syntax:**

WALLIX uses a special SSH connection format:

```ini
target_user@target_host@domain:service:account:bastion_user@bastion_ip
```

Example: `root@local@server1:SSH:my_authorization:piviledgeuser@192.168.1.75`

Where:

- `root` = user on the target server
- `local` = WALLIX domain of the target
- `server1` = target server name in WALLIX
- `SSH` = service
- `my_authorization` = WALLIX account name
- `piviledgeuser` = bastion user (for proxy authentication)
- `192.168.1.75` = bastion IP

**Important:** WALLIX Bastion has two different access methods:

- **Administrative access:** Port 2242 with `wabadmin` (for managing the bastion itself)
- **Proxy access:** Port 22 with special syntax (for accessing target servers through the bastion)

This approach:

- Centralizes access control through the bastion
- Eliminates need for direct network access to target servers
- Maintains comprehensive audit trail through WALLIX
- Uses WALLIX's built-in connection routing

## Prerequisites

- WALLIX Bastion accessible from Ansible controller
- Target servers configured in WALLIX Bastion
- Bastion user credentials (e.g., `piviledgeuser`) with appropriate permissions
- WALLIX domain, service, and account names

## Configuration

### Understanding WALLIX Connection String

The connection format is:

```ini
target_user@target_host@domain:service:account:bastion_user@bastion_ip
```

You need to know:

1. **Target credentials** - User and IP of the server you want to reach
2. **WALLIX configuration** - Domain name (e.g., `local`), service (e.g., `SSH`), account name (e.g., `my_authorization`)
3. **Bastion credentials** - User (e.g., `piviledgeuser`) and IP of the bastion

### Inventory Setup

**inventory.ini:**

```ini
[bastion]
# Direct administrative access to the bastion (management interface)
wallix-bastion ansible_host=192.168.1.75 ansible_port=2242 ansible_user=wabadmin

# Example: root@local@target1:SSH:my_authorization:piviledgeuser@192.168.1.75
[remote_servers]
# Target servers behind the bastion using WALLIX proxy syntax
# WALLIX Format: <targetACCOUNT>@<DOMAIN>@<DEVICE_NAME>:<SERVICE>:<AUTHORIZATION>:<MY_ID>@<BASTION_IP>
# - DOMAIN: domaine au sens bastion (ex: local)
# - DEVICE_NAME: nom de la machine cible dans le bastion (ex: target1)
# Example: root@local@target1:SSH:my_authorization:piviledgeuser@192.168.1.75
remote-server-1 ansible_host='target1_account@local@target1:SSH:my_authorization:piviledgeuser@192.168.1.75' ansible_port=22
remote-server-2 ansible_host='target2_account@local@target2:SSH:my_authorization:piviledgeuser@192.168.1.75' ansible_port=22

[remote_servers:vars]
# WALLIX proxy configuration - NO ProxyCommand needed!
# The special WALLIX syntax in ansible_host handles everything
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

```

### Ansible Vault for Credentials

Create vault for bastion admin password:

```bash
mkdir -p group_vars/bastion

# Create vault for bastion credentials
ansible-vault create group_vars/bastion/vault.yml
```

Add to `group_vars/bastion/vault.yml`:

```yaml
---
vault_bastion_password: "your_wabadmin_password"
```

Create `group_vars/bastion/vars.yml`:

```yaml
---
ansible_password: "{{ vault_bastion_password }}"
```

Create vault for WALLIX proxy user password:

```bash
mkdir -p group_vars/remote_servers
ansible-vault create group_vars/remote_servers/vault.yml
```

Add to `group_vars/remote_servers/vault.yml`:

```yaml
---
# Password for the bastion user (piviledgeuser) used in proxy connection
vault_proxy_password: "your_bastion_user_password"
```

Create `group_vars/remote_servers/vars.yml`:

```yaml
---
# Password used for WALLIX proxy authentication
ansible_password: "{{ vault_proxy_password }}"
```

**Note:** The `ansible_password` for remote_servers is the bastion user password (`piviledgeuser`), not the target server password. WALLIX handles the target server authentication.

## Usage Examples

### Basic Connection Test

```bash
# Test bastion administrative connection
ansible bastion -i inventory.ini -m ping --ask-vault-pass

# Test remote servers through WALLIX proxy
ansible remote_servers -i inventory.ini -m ping --ask-vault-pass
```

### Manual SSH Test

Test the WALLIX proxy syntax manually:

```bash
# Test de connexion au bastion (accès proxy)
# Format: <targetACCOUNT>@<DOMAIN>@<DEVICE_NAME>:<SERVICE>:<AUTHORIZATION>:<MY_ID>@<BASTION_IP>
ssh -p 22 'root@local@target1:SSH:my_authorization:piviledgeuser@192.168.1.75' -o StrictHostKeyChecking=no whoami
```

### Run Playbook

```bash
ansible-playbook -i inventory.ini proxy_example.yml --ask-vault-pass
```

## Advanced: Mixed Environment Configuration

For environments where only some hosts are behind WALLIX:

**inventory.ini:**

```ini
[bastion]
wallix-bastion ansible_host=192.168.1.75 ansible_port=2242 ansible_user=wabadmin

[behind_wallix]
# Servers accessible through WALLIX proxy
server1 ansible_host='root@local@server1:SSH:my_authorization:piviledgeuser@192.168.1.75' ansible_user=root ansible_port=22
server2 ansible_host='root@local@server2:SSH:my_authorization:piviledgeuser@192.168.1.75' ansible_user=root ansible_port=22

[behind_wallix:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[direct_access]
# Directly accessible servers (no WALLIX proxy)
server3 ansible_host=203.0.113.10 ansible_user=admin
```

## Troubleshooting

### Connection Timeout

Increase SSH timeout:

```ini
[remote_servers:vars]
ansible_ssh_common_args='-o ConnectTimeout=30 -o StrictHostKeyChecking=no'

ansible_ssh_common_args='-o ConnectTimeout=30 -o ProxyCommand="ssh -W %h:%p -p 22 piviledgeuser@192.168.1.75"'
```

### Authentication Issues

Test manual SSH connection with WALLIX syntax:

```bash
# Test bastion administrative access
ssh -p 2242 wabadmin@192.168.1.75

# Test WALLIX proxy connection
ssh -p 22 'root@local@target1:SSH:my_authorization:piviledgeuser@192.168.1.75'
# You'll be prompted for the piviledgeuser (bastion user) password
```

### Invalid Target Error

If you get "Invalid target", verify:

- The WALLIX connection string format is correct
- The domain name (`local`), service (`SSH`), and account name (`my_authorization`) match your WALLIX configuration
- The target server is configured in WALLIX with proper access rights

### Wrong Password Prompt

Remember:

- For direct bastion access (port 2242): use `wabadmin` password
- For WALLIX proxy (port 22 with special syntax): use bastion user password (`piviledgeuser`)
- WALLIX handles authentication to the target server automatically

### Debug Mode

Run with verbose output:

```bash
ansible-playbook -i inventory.ini proxy_example.yml --ask-vault-pass -vvvv
```

## Security Considerations

- Store all passwords in Ansible Vault
- Use SSH keys when possible instead of passwords
- Configure `StrictHostKeyChecking=yes` in production (shown as `no` for examples)
- Regularly rotate credentials
- Monitor bastion logs for unauthorized access attempts

## Files

- `inventory.ini` - Example inventory with proxy configuration
- `proxy_example.yml` - Example playbook using bastion as proxy
- `group_vars/` - Vault-encrypted credentials

## References

- [Ansible SSH Connection](https://docs.ansible.com/ansible/latest/plugins/connection/ssh.html)
- [SSH ProxyCommand](https://man.openbsd.org/ssh_config#ProxyCommand)
- [SSH ProxyJump](https://man.openbsd.org/ssh_config#ProxyJump)
