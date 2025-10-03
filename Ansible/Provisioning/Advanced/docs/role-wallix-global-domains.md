# WALLIX Global Domains Management Role

## Overview

The `wallix-global-domains` role manages global domains in WALLIX Bastion for organizing devices into logical groups based on network segments, departments, or security zones.

## Purpose

- Create and manage global domains for device organization
- Configure domain-specific settings and policies
- Organize devices by network segments or business units
- Facilitate access control and policy management

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_global_domains` - List of global domains to manage

### Optional Variables

- `wallix_global_domains_mode` - Operation mode (normal, dry_run)

## Usage

### Basic Global Domain Creation

```yaml
- name: Create global domains
  include_role:
    name: wallix-global-domains
  vars:
    wallix_global_domains:
      - name: "production"
        description: "Production environment servers"
        admin_account: "admin"
        enable_password_vault: true
      - name: "development"
        description: "Development environment"
        admin_account: "dev-admin"
        enable_password_vault: false
```

### Advanced Configuration

```yaml
- name: Configure global domains with policies
  include_role:
    name: wallix-global-domains
  vars:
    wallix_global_domains_mode: "normal"
    wallix_global_domains:
      - name: "dmz"
        description: "DMZ network segment"
        admin_account: "dmz-admin"
        enable_password_vault: true
        password_policy:
          min_length: 12
          complexity_required: true
          rotation_days: 90
        network_settings:
          allowed_subnets: ["10.1.0.0/24", "10.2.0.0/24"]
          default_gateway: "10.1.0.1"
```

## Configuration Options

### Global Domain Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique domain name |
| `description` | No | Domain description |
| `admin_account` | Yes | Default admin account for the domain |
| `enable_password_vault` | No | Enable password vault for domain |
| `state` | No | present/absent (default: present) |

### Password Policy Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `min_length` | `8` | Minimum password length |
| `complexity_required` | `false` | Require complex passwords |
| `rotation_days` | `0` | Password rotation period (0=disabled) |
| `history_count` | `0` | Password history count |

## Examples

### Network-Based Domains

```yaml
wallix_global_domains:
  - name: "internal"
    description: "Internal corporate network"
    admin_account: "internal-admin"
    enable_password_vault: true
    network_settings:
      allowed_subnets: ["192.168.0.0/16", "10.0.0.0/8"]
  
  - name: "external"
    description: "External facing services"
    admin_account: "external-admin"
    enable_password_vault: true
    security_settings:
      require_mfa: true
      session_timeout: 1800
```

### Environment-Based Domains

```yaml
wallix_global_domains:
  - name: "prod"
    description: "Production environment"
    admin_account: "prod-admin"
    enable_password_vault: true
    password_policy:
      min_length: 14
      complexity_required: true
      rotation_days: 60
  
  - name: "test"
    description: "Test environment"
    admin_account: "test-admin"
    enable_password_vault: false
    password_policy:
      min_length: 8
      complexity_required: false
```

## Operation Modes

- **normal** - Standard operation mode
- **dry_run** - Validate without making changes

## Outputs

After execution, provides:

- `wallix_global_domains_created` - Number of domains created
- `wallix_global_domains_status` - Overall operation status
- `domain_creation_results` - Detailed creation results

## Use Cases

### Network Segmentation

Use global domains to mirror your network topology:

- DMZ domain for internet-facing servers
- Internal domain for corporate resources
- Management domain for infrastructure devices

### Environment Separation

Organize by deployment environments:

- Production domain with strict policies
- Staging domain with moderate policies
- Development domain with relaxed policies

### Department Organization

Structure by business units:

- Finance domain for financial systems
- HR domain for human resources
- IT domain for infrastructure

## Security Considerations

- Configure appropriate password policies per domain
- Use different admin accounts for each domain
- Implement network restrictions where applicable
- Enable password vault for sensitive domains

## Error Handling

- Validates domain parameters before creation
- Checks for duplicate domain names
- Provides detailed error messages for failures
- Supports rollback on configuration errors

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Used by**: wallix-devices (device assignment), wallix-global-accounts (account organization)
- **Related**: wallix-domains (authentication domains), wallix-authorizations (access control)
