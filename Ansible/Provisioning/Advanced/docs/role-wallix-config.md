# WALLIX Configuration Management Role

## Overview

The `wallix-config` role manages system-level configuration settings for WALLIX Bastion, including license management, system parameters, and global policies.

## Purpose

- Configure WALLIX Bastion system settings
- Manage license configuration
- Set up global security policies
- Configure system parameters and thresholds

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_config` - Configuration management settings

### Optional Variables

- `wallix_license_config` - License configuration
- `wallix_system_config` - System-level settings

## Usage

### Basic Configuration Management

```yaml
- name: Configure WALLIX system
  include_role:
    name: wallix-config
  vars:
    wallix_config:
      validate_before_apply: true
      backup_before_change: true
      manage_system_config: true
      manage_license: false
    
    wallix_system_config:
      session_timeout: 3600
      max_concurrent_sessions: 100
      enable_session_recording: true
      log_level: "INFO"
```

### Complete System Configuration

```yaml
- name: Full WALLIX configuration
  include_role:
    name: wallix-config
  vars:
    wallix_config:
      validate_before_apply: true
      backup_before_change: true
      manage_system_config: true
      manage_license: true
      manage_security_policies: true
    
    wallix_license_config:
      license_key: "{{ vault_wallix_license_key }}"
      license_type: "enterprise"
      max_users: 500
      max_devices: 1000
      features: ["session_recording", "password_vault", "reporting"]
    
    wallix_system_config:
      # Session settings
      session_timeout: 1800
      idle_timeout: 900
      max_concurrent_sessions: 200
      session_recording: true
      
      # Security settings
      password_policy:
        min_length: 12
        complexity_required: true
        expiration_days: 90
      
      # Network settings
      allowed_ip_ranges: ["10.0.0.0/8", "192.168.0.0/16"]
      dns_servers: ["8.8.8.8", "8.8.4.4"]
      ntp_servers: ["pool.ntp.org"]
      
      # Logging settings
      log_level: "INFO"
      audit_logging: true
      syslog_server: "syslog.company.com"
      syslog_port: 514
```

## Configuration Options

### System Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `session_timeout` | `3600` | Session timeout in seconds |
| `idle_timeout` | `1800` | Idle timeout in seconds |
| `max_concurrent_sessions` | `100` | Maximum concurrent sessions |
| `session_recording` | `true` | Enable session recording |
| `log_level` | `INFO` | System log level |
| `audit_logging` | `true` | Enable audit logging |

### License Configuration

| Parameter | Required | Description |
|-----------|----------|-------------|
| `license_key` | Yes | WALLIX license key |
| `license_type` | No | License type (basic, standard, enterprise) |
| `max_users` | No | Maximum number of users |
| `max_devices` | No | Maximum number of devices |
| `features` | No | Enabled features list |

### Security Policy Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `password_policy` | `{}` | Password policy settings |
| `allowed_ip_ranges` | `[]` | Allowed IP address ranges |
| `failed_login_threshold` | `5` | Failed login attempt threshold |
| `lockout_duration` | `300` | Account lockout duration (seconds) |
| `enable_mfa` | `false` | Enable multi-factor authentication |

## Examples

### High-Security Configuration

```yaml
wallix_system_config:
  # Strict session settings
  session_timeout: 900
  idle_timeout: 300
  max_concurrent_sessions: 50
  session_recording: true
  session_encryption: "AES256"
  
  # Strong password policy
  password_policy:
    min_length: 16
    complexity_required: true
    expiration_days: 60
    history_count: 12
    lockout_threshold: 3
    lockout_duration: 900
  
  # Network restrictions
  allowed_ip_ranges: ["10.100.0.0/16"]
  deny_unknown_ips: true
  
  # Enhanced logging
  log_level: "DEBUG"
  audit_logging: true
  detailed_logging: true
  syslog_server: "secure-syslog.company.com"
  syslog_port: 6514
  syslog_protocol: "TLS"
```

### Development Environment Configuration

```yaml
wallix_system_config:
  # Relaxed session settings
  session_timeout: 7200
  idle_timeout: 3600
  max_concurrent_sessions: 500
  session_recording: false
  
  # Basic password policy
  password_policy:
    min_length: 8
    complexity_required: false
    expiration_days: 0
  
  # Open network access
  allowed_ip_ranges: ["0.0.0.0/0"]
  
  # Minimal logging
  log_level: "WARN"
  audit_logging: false
```

### Enterprise License Configuration

```yaml
wallix_license_config:
  license_key: "{{ vault_enterprise_license_key }}"
  license_type: "enterprise"
  max_users: 1000
  max_devices: 5000
  features:
    - "session_recording"
    - "password_vault"
    - "reporting"
    - "clustering"
    - "api_access"
    - "ldap_integration"
    - "mfa_support"
  
  support_level: "premium"
  maintenance_expiry: "2025-12-31"
```

### Network and Infrastructure Settings

```yaml
wallix_system_config:
  # Network configuration
  dns_servers: ["10.0.1.10", "10.0.1.11"]
  ntp_servers: ["ntp1.company.com", "ntp2.company.com"]
  proxy_server: "proxy.company.com:8080"
  
  # Certificate management
  ssl_certificate_path: "/etc/ssl/certs/wallix.crt"
  ssl_private_key_path: "/etc/ssl/private/wallix.key"
  ca_certificate_path: "/etc/ssl/certs/company-ca.crt"
  
  # Database settings
  database_backup_retention: 30
  database_optimization: true
  
  # Performance tuning
  max_memory_usage: "80%"
  cache_size: "1GB"
  connection_pool_size: 100
```

## Management Features

### Configuration Backup

- Automatic backup before changes
- Configuration versioning
- Rollback capabilities
- Export/import functionality

### Validation

- Pre-deployment validation
- Configuration syntax checking
- Dependency verification
- Impact assessment

### Monitoring

- Configuration drift detection
- Change tracking
- Compliance checking
- Alert notifications

## Operation Modes

- **apply** - Apply configuration changes
- **dry_run** - Validate without making changes
- **validate_only** - Only validate configuration
- **backup_only** - Create backup without changes

## Outputs

After execution, provides:

- `config_validation_results` - Configuration validation results
- `backup_results` - Backup operation results
- `system_config_results` - System configuration results
- `license_config_results` - License configuration results

## Best Practices

### Security

- Always backup configuration before changes
- Use encrypted storage for sensitive settings
- Implement least-privilege access
- Regular security audits

### Performance

- Monitor resource usage after changes
- Test configuration in non-production first
- Implement gradual rollouts
- Monitor system performance

### Compliance

- Document all configuration changes
- Maintain configuration baselines
- Regular compliance checks
- Audit trail maintenance

## Error Handling

- Validates configuration parameters before applying
- Creates automatic backups before changes
- Provides detailed error messages
- Supports rollback on failure

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Used by**: All other roles (system configuration affects all operations)
- **Related**: wallix-cleanup (configuration cleanup), wallix-domains (domain configuration)
