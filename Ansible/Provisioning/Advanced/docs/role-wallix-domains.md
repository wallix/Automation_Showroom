# WALLIX Domains Management Role

## Overview

The `wallix-domains` role manages authentication domains and global domains in WALLIX Bastion. It handles LDAP, Active Directory, RADIUS, and other external authentication sources.

## Purpose

- Configure authentication domains (LDAP, AD, RADIUS)
- Manage global domains for device organization
- Set up external authentication integration
- Configure domain-specific settings and policies

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_auth_domains` - Authentication domains configuration

### Optional Variables

- `wallix_domains` - Domain management settings
- `wallix_global_domains` - Global domains configuration

## Usage

### Basic Domain Configuration

```yaml
- name: Configure WALLIX domains
  include_role:
    name: wallix-domains
  vars:
    wallix_auth_domains:
      local:
        name: "local"
        type: "local"
        description: "Local WALLIX authentication"
      external_domains:
        - name: "company_ldap"
          type: "ldap"
          description: "Company LDAP directory"
          ldap_config:
            server: "ldap.company.com"
            port: 389
            base_dn: "dc=company,dc=com"
            bind_dn: "cn=admin,dc=company,dc=com"
            bind_password: "{{ vault_ldap_password }}"
```

### Complete Domain Setup

```yaml
- name: Full domain configuration
  include_role:
    name: wallix-domains
  vars:
    wallix_domains:
      manage_auth_domains: true
      manage_global_domains: true
      manage_ldap_domains: true
      manage_ad_domains: true
      operation_mode: "apply"
      validate_before_apply: true
    
    wallix_auth_domains:
      local:
        name: "local"
        type: "local"
        description: "Local authentication"
      
      external_domains:
        - name: "company_ad"
          type: "active_directory"
          description: "Company Active Directory"
          ad_config:
            domain: "company.local"
            server: "dc1.company.local"
            port: 389
            use_ssl: true
            bind_user: "svc_wallix@company.local"
            bind_password: "{{ vault_ad_password }}"
            base_dn: "dc=company,dc=local"
            user_search_base: "ou=Users,dc=company,dc=local"
            group_search_base: "ou=Groups,dc=company,dc=local"
```

## Configuration Options

### Domain Management Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `manage_auth_domains` | `true` | Manage authentication domains |
| `manage_global_domains` | `true` | Manage global domains |
| `manage_ldap_domains` | `true` | Manage LDAP domains |
| `manage_ad_domains` | `true` | Manage Active Directory domains |
| `operation_mode` | `apply` | Operation mode (apply, dry_run, validate_only) |
| `validate_before_apply` | `true` | Validate before applying changes |

### Domain Types

- **local** - Local WALLIX authentication
- **ldap** - LDAP directory services
- **active_directory** - Microsoft Active Directory
- **radius** - RADIUS authentication server
- **saml** - SAML identity provider
- **oauth** - OAuth identity provider

### LDAP Configuration

| Parameter | Required | Description |
|-----------|----------|-------------|
| `server` | Yes | LDAP server hostname/IP |
| `port` | Yes | LDAP port (389, 636) |
| `base_dn` | Yes | Base distinguished name |
| `bind_dn` | Yes | Bind user distinguished name |
| `bind_password` | Yes | Bind user password |
| `use_ssl` | No | Enable SSL/TLS connection |
| `user_search_base` | No | User search base DN |
| `group_search_base` | No | Group search base DN |

### Active Directory Configuration

| Parameter | Required | Description |
|-----------|----------|-------------|
| `domain` | Yes | AD domain name |
| `server` | Yes | Domain controller hostname |
| `port` | No | LDAP port (default: 389) |
| `use_ssl` | No | Enable LDAPS (default: false) |
| `bind_user` | Yes | Service account for binding |
| `bind_password` | Yes | Service account password |
| `base_dn` | Yes | Base DN for searches |

## Examples

### LDAP Domain Setup

```yaml
wallix_auth_domains:
  external_domains:
    - name: "openldap_users"
      type: "ldap"
      description: "OpenLDAP user directory"
      ldap_config:
        server: "ldap.internal.com"
        port: 389
        base_dn: "dc=internal,dc=com"
        bind_dn: "cn=wallix,ou=service,dc=internal,dc=com"
        bind_password: "{{ vault_ldap_bind_password }}"
        user_search_base: "ou=people,dc=internal,dc=com"
        group_search_base: "ou=groups,dc=internal,dc=com"
        use_ssl: false
        search_filter: "(objectClass=inetOrgPerson)"
```

### Active Directory Domain

```yaml
wallix_auth_domains:
  external_domains:
    - name: "corporate_ad"
      type: "active_directory"
      description: "Corporate Active Directory"
      ad_config:
        domain: "corp.company.com"
        server: "dc01.corp.company.com"
        port: 636
        use_ssl: true
        bind_user: "svc-wallix@corp.company.com"
        bind_password: "{{ vault_ad_service_password }}"
        base_dn: "dc=corp,dc=company,dc=com"
        user_search_base: "ou=Employees,dc=corp,dc=company,dc=com"
        group_search_base: "ou=Security Groups,dc=corp,dc=company,dc=com"
```

### RADIUS Authentication

```yaml
wallix_auth_domains:
  external_domains:
    - name: "radius_auth"
      type: "radius"
      description: "RADIUS authentication server"
      radius_config:
        server: "radius.company.com"
        port: 1812
        shared_secret: "{{ vault_radius_secret }}"
        timeout: 5
        retries: 3
        nas_identifier: "wallix-bastion"
```

## Operation Modes

- **apply** - Apply configuration changes
- **dry_run** - Validate without making changes
- **validate_only** - Only validate configuration syntax

## Outputs

After execution, provides:

- `auth_domain_results` - Authentication domain configuration results
- `ldap_domain_results` - LDAP domain setup results
- `ad_domain_results` - Active Directory domain results
- `domain_validation_results` - Validation results

## Security Considerations

- Always use vault-encrypted passwords for bind credentials
- Enable SSL/TLS for production LDAP/AD connections
- Use dedicated service accounts with minimal privileges
- Regularly rotate bind account passwords
- Validate certificate chains for SSL connections

## Error Handling

- Validates domain configuration before applying
- Tests connectivity to external authentication servers
- Provides detailed error messages for connection failures
- Supports retry mechanisms for transient failures

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Used by**: wallix-users (external user authentication), wallix-authorizations (domain-based access)
- **Related**: wallix-global-domains (device organization), wallix-config (system configuration)
