# WALLIX Global Accounts Management Role

## Overview

The `wallix-global-accounts` role manages global accounts in WALLIX Bastion, which are shared accounts that can be used across multiple devices within global domains.

## Purpose

- Create and manage global accounts for shared access
- Configure account credentials and policies
- Associate accounts with global domains
- Manage account passwords and rotation policies

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication
- **wallix-global-domains** - Should be executed before to create domains

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_global_accounts` - List of global accounts to manage

### Optional Variables

- `wallix_global_domains` - Global domains to create/verify
- `wallix_global_accounts_mode` - Operation mode

## Usage

### Basic Global Account Creation

```yaml
- name: Create global accounts
  include_role:
    name: wallix-global-accounts
  vars:
    wallix_global_accounts:
      - name: "admin"
        description: "Global admin account"
        login: "administrator"
        domain: "production"
        password: "{{ vault_global_admin_password }}"
        auto_change_password: true
      - name: "service"
        description: "Service account"
        login: "svc-app"
        domain: "production"
        password: "{{ vault_service_password }}"
        auto_change_password: false
```

### Complete Account Management

```yaml
- name: Manage global accounts with domains
  include_role:
    name: wallix-global-accounts
  vars:
    wallix_global_domains:
      - name: "production"
        description: "Production environment"
        admin_account: "admin"
        enable_password_vault: true
    
    wallix_global_accounts:
      - name: "admin"
        description: "Production admin account"
        login: "root"
        domain: "production"
        password: "{{ vault_prod_admin_password }}"
        auto_change_password: true
        password_policy:
          change_frequency: 30
          complexity: "high"
        account_mapping:
          unix_uid: 0
          home_directory: "/root"
          shell: "/bin/bash"
```

## Configuration Options

### Global Account Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique account name |
| `description` | No | Account description |
| `login` | Yes | Login username |
| `domain` | Yes | Associated global domain |
| `password` | Yes | Account password (use vault) |
| `auto_change_password` | No | Enable automatic password changes |
| `state` | No | present/absent (default: present) |

### Password Policy Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `change_frequency` | `0` | Days between password changes (0=disabled) |
| `complexity` | `medium` | Password complexity (low, medium, high) |
| `length` | `12` | Minimum password length |
| `history_count` | `5` | Number of old passwords to remember |

### Account Mapping Options

| Parameter | Description |
|-----------|-------------|
| `unix_uid` | Unix user ID for the account |
| `windows_sid` | Windows SID for the account |
| `home_directory` | Default home directory |
| `shell` | Default shell for Unix accounts |
| `profile_path` | Windows profile path |

## Examples

### Unix/Linux Global Accounts

```yaml
wallix_global_accounts:
  - name: "root-prod"
    description: "Production root account"
    login: "root"
    domain: "production"
    password: "{{ vault_root_password }}"
    auto_change_password: true
    password_policy:
      change_frequency: 30
      complexity: "high"
      length: 16
    account_mapping:
      unix_uid: 0
      home_directory: "/root"
      shell: "/bin/bash"
  
  - name: "oracle-prod"
    description: "Oracle database account"
    login: "oracle"
    domain: "production"
    password: "{{ vault_oracle_password }}"
    auto_change_password: true
    account_mapping:
      unix_uid: 1001
      home_directory: "/home/oracle"
      shell: "/bin/bash"
```

### Windows Global Accounts

```yaml
wallix_global_accounts:
  - name: "admin-windows"
    description: "Windows admin account"
    login: "Administrator"
    domain: "windows-prod"
    password: "{{ vault_windows_admin_password }}"
    auto_change_password: true
    password_policy:
      change_frequency: 45
      complexity: "high"
      length: 14
    account_mapping:
      windows_sid: "S-1-5-21-1234567890-1234567890-1234567890-500"
      profile_path: "C:\\Users\\Administrator"
  
  - name: "service-sqlserver"
    description: "SQL Server service account"
    login: "svc-sqlserver"
    domain: "windows-prod"
    password: "{{ vault_sqlserver_password }}"
    auto_change_password: false
    account_mapping:
      windows_sid: "S-1-5-21-1234567890-1234567890-1234567890-1001"
```

### Multi-Domain Accounts

```yaml
wallix_global_domains:
  - name: "infrastructure"
    description: "Infrastructure domain"
    admin_account: "infra-admin"
  - name: "applications"
    description: "Application servers domain"
    admin_account: "app-admin"

wallix_global_accounts:
  - name: "monitoring"
    description: "Monitoring service account"
    login: "monitor"
    domain: "infrastructure"
    password: "{{ vault_monitor_password }}"
    auto_change_password: true
  
  - name: "deploy"
    description: "Deployment account"
    login: "deploy"
    domain: "applications"
    password: "{{ vault_deploy_password }}"
    auto_change_password: true
```

## Operation Modes

- **normal** - Standard operation mode
- **dry_run** - Validate without making changes
- **validate_only** - Only validate configuration

## Outputs

After execution, provides:

- `global_account_results` - Account creation results
- `domain_management_results` - Domain setup results
- `credential_management_results` - Password/credential results

## Password Management Features

### Automatic Password Changes

- Configurable change frequency
- Secure password generation
- Password history tracking
- Notification of password changes

### Password Policies

- **Low complexity**: Basic password requirements
- **Medium complexity**: Mixed case and numbers
- **High complexity**: Mixed case, numbers, and special characters

## Use Cases

### Shared Service Accounts

Create accounts that can be used across multiple devices:

- Database service accounts
- Application service accounts
- Monitoring accounts
- Backup accounts

### Administrative Accounts

Manage privileged accounts with consistent policies:

- Root/Administrator accounts
- Service desk accounts
- Emergency access accounts

### Application Integration

Accounts for automated systems:

- CI/CD deployment accounts
- API service accounts
- Inter-system communication accounts

## Security Considerations

- Use vault encryption for all passwords
- Enable automatic password rotation for privileged accounts
- Implement strong password policies
- Monitor account usage and access patterns
- Regularly audit account permissions

## Error Handling

- Validates account parameters before creation
- Checks domain existence before account creation
- Verifies password policy compliance
- Provides detailed error messages for failures

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication), wallix-global-domains (domain creation)
- **Used by**: wallix-authorizations (account access), wallix-devices (account assignment)
- **Related**: wallix-users (user accounts), wallix-policies (access policies)
