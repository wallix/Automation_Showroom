# Roles Reference

This document provides detailed information about each role included in the WALLIX PAM Ansible Collection.

## 📋 Role Overview

| Role                                                      | Category       | Description                               |
| --------------------------------------------------------- | -------------- | ----------------------------------------- |
| [wallix-auth](#wallix-auth)                               | Authentication | API authentication and session management |
| [wallix-devices](#wallix-devices)                         | Infrastructure | Device and service configuration          |
| [wallix-global-domains](#wallix-global-domains)           | Infrastructure | Global domain (LDAP/AD) configuration     |
| [wallix-global-accounts](#wallix-global-accounts)         | Infrastructure | Global account management                 |
| [wallix-domains](#wallix-domains)                         | Infrastructure | Domain-specific authentication            |
| [wallix-users](#wallix-users)                             | Access Control | User and user group management            |
| [wallix-authorizations](#wallix-authorizations)           | Access Control | Authorization and target group management |
| [wallix-timeframes](#wallix-timeframes)                   | Policies       | Timeframe definitions                     |
| [wallix-connection-policies](#wallix-connection-policies) | Policies       | Connection policy management              |
| [wallix-policies](#wallix-policies)                       | Policies       | Generic policy management                 |
| [wallix-applications](#wallix-applications)               | Integration    | Application integration management        |
| [wallix-config](#wallix-config)                           | Maintenance    | Bastion system configuration              |
| [wallix-cleanup](#wallix-cleanup)                         | Maintenance    | Safe resource cleanup                     |

---

## wallix-auth

**Category:** Authentication
**Purpose:** Authenticate with WALLIX Bastion API and manage sessions

### Variables

```yaml
wallix_bastion_host: "bastion.example.com"
wallix_bastion_port: 443
wallix_bastion_protocol: "https"

wallix_auth:
  # Authentication method: credentials or api_key
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
    renewal_threshold: 300 # seconds
    max_session_duration: 3600
    cleanup_on_exit: true

  connection:
    verify_ssl: true
    timeout: 30
    retry_count: 3
    retry_delay: 5
```

### Usage

```yaml
- name: Authenticate with WALLIX Bastion
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
```

### Tasks

- `authenticate.yml` - Perform initial API authentication
- `session_management.yml` - Manage session cookies and renewal
- `validate_connectivity.yml` - Verify API connectivity

---

## wallix-devices

**Category:** Infrastructure  
**Purpose:** Create, configure, and manage devices (servers, network equipment)

### Variables

```yaml
wallix_devices:
  - name: "web-server-01"
    host: "10.0.1.100"
    description: "Production web server"
    type: "server"
    state: "present"

wallix_device_services:
  - name: "web-ssh"
    device_name: "web-server-01"
    protocol: "SSH"
    port: 22
    connection_policy: "default"
    state: "present"

wallix_device_accounts:
  - name: "web-admin"
    device_name: "web-server-01"
    login: "admin"
    description: "Web server admin account"
    auto_change_password: false
    state: "present"
```

### Usage

```yaml
- name: Configure devices
  hosts: bastion
  vars_files:
    - vars/devices.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-devices
```

---

## wallix-users

**Category:** Access Control  
**Purpose:** Create users, manage groups, and configure credentials

### Variables

```yaml
wallix_user_groups:
  - name: "admins"
    description: "System administrators"
    profile: "administrator"
    state: "present"

wallix_users:
  - name: "john.doe"
    display_name: "John Doe"
    email: "john.doe@example.com"
    groups:
      - "admins"
    authentication:
      - type: "password"
        password: "{{ vault_user_password }}"
    state: "present"
```

### Usage

```yaml
- name: Configure users
  hosts: bastion
  vars_files:
    - vars/users.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-users
```

---

## wallix-authorizations

**Category:** Access Control  
**Purpose:** Create authorization rules and target groups

### Variables

```yaml
wallix_target_groups:
  - group_name: "production-servers"
    description: "All production servers"
    state: "present"

wallix_authorizations:
  - name: "admin-prod-access"
    description: "Admin access to production"
    user_group: "admins"
    target_group: "production-servers"
    authorization_type: "RDP,SSH"
    is_critical: true
    is_recorded: true
    approval_required: false
    state: "present"
```

### Usage

```yaml
- name: Configure authorizations
  hosts: bastion
  vars_files:
    - vars/authorizations.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-authorizations
```

---

## wallix-global-domains

**Category:** Infrastructure  
**Purpose:** Create and manage global authentication domains (LDAP/AD)

### Variables

```yaml
wallix_global_domains:
  - name: "corp-ad"
    type: "ActiveDirectory"
    description: "Corporate Active Directory"
    ldap_host: "dc.example.com"
    ldap_port: 636
    ldap_ssl: true
    base_dn: "DC=example,DC=com"
    bind_dn: "CN=svc_wallix,OU=Services,DC=example,DC=com"
    bind_password: "{{ vault_ldap_password }}"
    state: "present"
```

### Usage

```yaml
- name: Configure global domains
  hosts: bastion
  vars_files:
    - vars/domains.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-global-domains
```

---

## wallix-global-accounts

**Category:** Infrastructure  
**Purpose:** Create and manage global accounts with credential management

### Variables

```yaml
wallix_global_accounts:
  - name: "svc-backup"
    domain: "corp-ad"
    login: "svc_backup"
    description: "Backup service account"
    auto_change_password: true
    checkout_policy: "shared"
    state: "present"
```

### Usage

```yaml
- name: Configure global accounts
  hosts: bastion
  vars_files:
    - vars/accounts.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-global-domains
    - role: wallix.pam.wallix-global-accounts
```

---

## wallix-domains

**Category:** Infrastructure  
**Purpose:** Create and configure domain-specific authentication and authorization

### Variables

```yaml
wallix_domains:
  - name: "local"
    description: "Local authentication domain"
    type: "local"
    state: "present"
```

### Usage

```yaml
- name: Configure domains
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-domains
```

---

## wallix-timeframes

**Category:** Policies  
**Purpose:** Create and manage timeframes for scheduled access

### Variables

```yaml
wallix_timeframes:
  - timeframe_name: "business-hours"
    description: "Monday to Friday, 9am-6pm"
    periods:
      - start_time: "09:00"
        end_time: "18:00"
        days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
    state: "present"
```

### Usage

```yaml
- name: Configure timeframes
  hosts: bastion
  vars_files:
    - vars/timeframes.yml
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-timeframes
```

---

## wallix-connection-policies

**Category:** Policies  
**Purpose:** Create and manage connection policies for session control

### Variables

```yaml
wallix_connection_policies:
  - name: "ssh-standard"
    description: "Standard SSH connection policy"
    protocol: "SSH"
    options:
      record_session: true
      allow_file_transfer: false
    state: "present"
```

### Usage

```yaml
- name: Configure connection policies
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-connection-policies
```

---

## wallix-policies

**Category:** Policies  
**Purpose:** Create and manage generic policies (access, compliance, audit)

### Variables

```yaml
wallix_policies:
  - name: "compliance-policy"
    description: "SOC2 compliance policy"
    type: "audit"
    settings:
      log_retention_days: 365
    state: "present"
```

### Usage

```yaml
- name: Configure policies
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-policies
```

---

## wallix-applications

**Category:** Integration  
**Purpose:** Create and manage applications for integration points

### Variables

```yaml
wallix_applications:
  - name: "jenkins-integration"
    description: "Jenkins CI/CD integration"
    type: "api_client"
    state: "present"
```

### Usage

```yaml
- name: Configure applications
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-applications
```

---

## wallix-config

**Category:** Maintenance  
**Purpose:** Configure system settings, clustering, licensing, certificates

### Variables

```yaml
wallix_config:
  smtp:
    server: "smtp.example.com"
    port: 587
    use_tls: true
    sender: "wallix@example.com"

  x509:
    enable: true
    ca_certificate: "{{ lookup('file', 'certs/ca.pem') }}"

  session_options:
    default_timeout: 3600
    max_connections: 100
```

### Usage

```yaml
- name: Configure bastion settings
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-config
```

---

## wallix-cleanup

**Category:** Maintenance  
**Purpose:** Safe resource cleanup with backup capabilities

### Variables

```yaml
wallix_cleanup:
  backup_before_delete: true
  backup_path: "/tmp/wallix_backup"

  # Resources to clean up
  cleanup_authorizations: true
  cleanup_target_groups: true
  cleanup_users: true
  cleanup_user_groups: true
  cleanup_devices: true

  # Confirmation required
  confirm_cleanup: true
```

### Usage

```yaml
- name: Cleanup resources
  hosts: bastion
  roles:
    - role: wallix.pam.wallix-auth
    - role: wallix.pam.wallix-cleanup
      vars:
        wallix_cleanup:
          backup_before_delete: true
          cleanup_authorizations: true
          confirm_cleanup: true
```

---

## 🔄 Role Dependencies

All roles depend on `wallix-auth` for API authentication. Here's the recommended execution order:

```text
1. wallix-auth           # Always first - handles authentication
2. wallix-config         # System configuration
3. wallix-global-domains # External domains (AD/LDAP)
4. wallix-global-accounts # Global accounts
5. wallix-devices        # Infrastructure (devices, services, local accounts)
6. wallix-domains        # Domain configuration
7. wallix-users          # Users and groups
8. wallix-timeframes     # Time-based policies
9. wallix-connection-policies # Connection policies
10. wallix-policies      # Generic policies
11. wallix-authorizations # Access rules (depends on users, devices, timeframes)
12. wallix-applications  # External integrations
13. wallix-cleanup       # Cleanup operations (use with caution)
```

## 📖 See Also

- [Installation Guide](installation.md)
- [Examples](../examples/)
- [Main README](../README.md)
