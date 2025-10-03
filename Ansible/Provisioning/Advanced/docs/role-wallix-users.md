# WALLIX Users Management Role

## Overview

The `wallix-users` role manages user accounts, groups, and credentials in WALLIX Bastion. It handles user creation, group membership, and various authentication methods.

## Purpose

- Create and manage WALLIX user accounts
- Configure user groups and membership
- Manage user credentials (passwords, SSH keys, certificates)
- Set up user preferences and profiles

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_users` - List of users to manage

### Optional Variables

- `wallix_user_groups` - User groups configuration
- `wallix_users_mode` - Operation mode (normal, dry_run, validate_only)

## Usage

### Basic User Creation

```yaml
- name: Create WALLIX users
  include_role:
    name: wallix-users
  vars:
    wallix_users:
      - name: "admin.user"
        display_name: "Admin User"
        email: "admin.user@company.com"
        profile: "administrator"
        password: "{{ vault_admin_password }}"
      - name: "standard.user"
        display_name: "Standard User"
        email: "user@company.com"
        profile: "user"
        password: "{{ vault_user_password }}"
```

### Complete User Management

```yaml
- name: Manage users with groups and credentials
  include_role:
    name: wallix-users
  vars:
    wallix_user_groups:
      - name: "administrators"
        description: "System administrators"
      - name: "operators"
        description: "System operators"
    
    wallix_users:
      - name: "admin.user"
        display_name: "Admin User"
        email: "admin.user@company.com"
        profile: "administrator"
        groups: ["administrators"]
        password: "{{ vault_admin_password }}"
        credentials:
          authentication_methods: ["local_password", "ssh_key"]
          ssh_public_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... admin@company.com"
```

## Configuration Options

### User Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique username |
| `display_name` | No | Full display name |
| `email` | No | User email address |
| `profile` | Yes | User profile (administrator, user, etc.) |
| `password` | No | User password (use vault) |
| `groups` | No | List of group memberships |
| `state` | No | present/absent (default: present) |

### User Group Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Group name |
| `description` | No | Group description |
| `state` | No | present/absent (default: present) |

### Credential Types

- **local_password** - Local WALLIX password
- **ssh_key** - SSH public key authentication
- **certificate** - X.509 certificate authentication
- **gpg** - GPG key authentication

## User Profiles

- **administrator** - Full administrative access
- **user** - Standard user access
- **auditor** - Read-only audit access
- **operator** - Operational access
- **custom** - Custom profile with specific permissions

## Examples

### Mixed User Types

```yaml
wallix_users:
  - name: "system.admin"
    display_name: "System Administrator"
    email: "sysadmin@company.com"
    profile: "administrator"
    groups: ["administrators"]
    password: "{{ vault_sysadmin_password }}"
    
  - name: "audit.user"
    display_name: "Audit User"
    email: "audit@company.com"
    profile: "auditor"
    groups: ["auditors"]
    password: "{{ vault_audit_password }}"
    
  - name: "service.account"
    display_name: "Service Account"
    profile: "user"
    credentials:
      authentication_methods: ["ssh_key"]
      ssh_public_key: "{{ service_ssh_key }}"
```

### Advanced Credentials

```yaml
wallix_users:
  - name: "secure.admin"
    display_name: "Secure Administrator"
    email: "secure@company.com"
    profile: "administrator"
    credentials:
      authentication_methods: ["certificate", "ssh_key"]
      ssh_public_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
      certificate_dn: "CN=secure.admin,OU=IT,O=Company,C=US"
      certificate_file: "/path/to/secure.admin.crt"
```

## Outputs

After execution, provides:

- `user_creation_results` - Results of user creation
- `group_creation_results` - Group creation results
- `credential_management_results` - Credential configuration results
- `user_count` - Number of users processed

## Operation Modes

- **normal** - Standard operation mode
- **dry_run** - Validate without making changes
- **validate_only** - Only validate configuration

## Error Handling

- Validates user parameters before creation
- Checks for duplicate usernames
- Verifies email format
- Validates credential formats
- Provides detailed error messages

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Used by**: wallix-authorizations (user access), wallix-devices (user assignments)
- **Related**: wallix-domains (user authentication), wallix-global-accounts (account mapping)
