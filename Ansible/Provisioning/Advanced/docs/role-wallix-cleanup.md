# WALLIX Cleanup Management Role

## Overview

The `wallix-cleanup` role provides comprehensive cleanup capabilities for WALLIX Bastion, allowing safe removal of users, devices, domains, accounts, and other resources with proper validation and backup procedures.

## Purpose

- Safely clean up WALLIX Bastion resources
- Remove unused users, devices, and accounts
- Clean up orphaned configurations
- Backup resources before deletion
- Validate cleanup operations for safety

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_cleanup` - Cleanup configuration settings

### Optional Variables

- `wallix_cleanup_safety` - Safety validation settings
- Resource-specific cleanup variables

## Usage

### Basic Cleanup Operations

```yaml
- name: Clean up WALLIX resources
  include_role:
    name: wallix-cleanup
  vars:
    wallix_cleanup:
      operation_mode: "dry_run"
      require_confirmation: true
      backup_before_delete: true
      
      cleanup_targets:
        - users
        - devices
        - domains
        - accounts
    
    wallix_cleanup_safety:
      require_explicit_confirmation: false
```

### Comprehensive Cleanup with Safety Checks

```yaml
- name: Comprehensive WALLIX cleanup
  include_role:
    name: wallix-cleanup
  vars:
    wallix_cleanup:
      operation_mode: "apply"
      require_confirmation: false
      backup_before_delete: true
      detailed_logging: true
      
      cleanup_targets:
        - unused_users
        - orphaned_devices
        - empty_domains
        - expired_accounts
        - old_authorizations
      
      cleanup_criteria:
        user_inactive_days: 90
        device_last_access_days: 180
        account_unused_days: 60
        authorization_last_used_days: 120
      
      safety_checks:
        preserve_admin_users: true
        preserve_active_sessions: true
        validate_dependencies: true
        create_cleanup_report: true
    
    wallix_cleanup_safety:
      require_explicit_confirmation: true
      max_deletion_percentage: 20
      preserve_critical_resources: true
```

## Configuration Options

### Cleanup Operation Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `operation_mode` | `dry_run` | Operation mode (dry_run, apply) |
| `require_confirmation` | `true` | Require user confirmation |
| `backup_before_delete` | `true` | Create backup before deletion |
| `detailed_logging` | `false` | Enable detailed operation logging |
| `continue_on_error` | `false` | Continue cleanup on errors |

### Cleanup Targets

- **users** - Clean up user accounts
- **devices** - Remove devices
- **domains** - Clean up domains
- **accounts** - Remove accounts
- **authorizations** - Clean up access authorizations
- **target_groups** - Remove target groups
- **user_groups** - Clean up user groups
- **global_accounts** - Remove global accounts
- **global_domains** - Clean up global domains

### Cleanup Criteria

| Parameter | Default | Description |
|-----------|---------|-------------|
| `user_inactive_days` | `90` | Days of inactivity before user cleanup |
| `device_last_access_days` | `180` | Days since last device access |
| `account_unused_days` | `60` | Days of account inactivity |
| `authorization_last_used_days` | `120` | Days since last authorization use |
| `session_age_days` | `30` | Days before session cleanup |

### Safety Check Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `preserve_admin_users` | `true` | Never delete admin users |
| `preserve_active_sessions` | `true` | Skip resources with active sessions |
| `validate_dependencies` | `true` | Check for dependencies before deletion |
| `max_deletion_percentage` | `10` | Maximum percentage of resources to delete |
| `preserve_critical_resources` | `true` | Preserve critical system resources |

## Examples

### Safe Development Environment Cleanup

```yaml
wallix_cleanup:
  operation_mode: "apply"
  require_confirmation: false
  backup_before_delete: true
  
  cleanup_targets:
    - test_users
    - dev_devices
    - temporary_accounts
  
  cleanup_criteria:
    user_inactive_days: 30
    device_last_access_days: 60
    account_unused_days: 14
  
  safety_checks:
    preserve_admin_users: true
    preserve_active_sessions: true
    max_deletion_percentage: 50
```

### Production Environment Cleanup

```yaml
wallix_cleanup:
  operation_mode: "dry_run"
  require_confirmation: true
  backup_before_delete: true
  detailed_logging: true
  
  cleanup_targets:
    - orphaned_devices
    - expired_accounts
    - unused_authorizations
  
  cleanup_criteria:
    device_last_access_days: 365
    account_unused_days: 180
    authorization_last_used_days: 270
  
  safety_checks:
    preserve_admin_users: true
    preserve_active_sessions: true
    validate_dependencies: true
    max_deletion_percentage: 5
    preserve_critical_resources: true
  
  notification_settings:
    send_report: true
    email_recipients: ["admin@company.com"]
    report_format: "detailed"
```

### Targeted Resource Cleanup

```yaml
# Clean up specific user accounts
wallix_cleanup:
  operation_mode: "apply"
  backup_before_delete: true
  
  specific_cleanup:
    users_to_remove:
      - "temp.user1"
      - "contractor.john"
      - "intern.jane"
    
    devices_to_remove:
      - "old-server-01"
      - "decommissioned-workstation"
    
    domains_to_remove:
      - "test-domain"
      - "deprecated-ldap"
```

### Comprehensive System Cleanup

```yaml
wallix_cleanup:
  operation_mode: "apply"
  require_confirmation: false
  backup_before_delete: true
  detailed_logging: true
  
  cleanup_targets:
    - unused_users
    - orphaned_devices
    - empty_domains
    - expired_accounts
    - old_authorizations
    - empty_target_groups
    - unused_user_groups
    - orphaned_global_accounts
  
  cleanup_criteria:
    user_inactive_days: 120
    device_last_access_days: 300
    account_unused_days: 90
    authorization_last_used_days: 180
    group_empty_days: 60
  
  advanced_options:
    cleanup_logs_older_than: 365
    cleanup_backups_older_than: 30
    optimize_database: true
    update_statistics: true
```

## Operation Modes

### Dry Run Mode

- Validates cleanup operations without making changes
- Generates detailed report of what would be cleaned
- Identifies potential issues or dependencies
- Safe for production environments

### Apply Mode

- Executes actual cleanup operations
- Creates backups before deletion
- Requires appropriate confirmations
- Logs all cleanup activities

## Safety Features

### Pre-Cleanup Validation

- Dependency checking
- Active session validation
- Critical resource protection
- Administrative user preservation

### Backup and Recovery

- Automatic resource backup before deletion
- Configurable backup retention
- Easy restoration procedures
- Backup integrity verification

### Confirmation and Approval

- Multiple confirmation levels
- Administrative approval workflows
- Safety threshold enforcement
- Emergency stop capabilities

## Cleanup Reports

After execution, provides:

- `cleanup_report` - Detailed cleanup summary
- `backup_report` - Backup operation results
- `safety_report` - Safety check results
- `error_report` - Any errors encountered

## Use Cases

### Regular Maintenance

- Weekly cleanup of temporary resources
- Monthly removal of inactive accounts
- Quarterly cleanup of unused devices
- Annual comprehensive cleanup

### Project Decommissioning

- Remove project-specific users and devices
- Clean up temporary authorizations
- Remove project domains and accounts
- Archive project configurations

### Security Compliance

- Remove dormant accounts
- Clean up excessive permissions
- Remove outdated authorizations
- Maintain audit compliance

### Performance Optimization

- Remove unused resources to improve performance
- Clean up old logs and backups
- Optimize database after cleanup
- Update system statistics

## Error Handling

- Validates all parameters before starting cleanup
- Checks for active sessions and dependencies
- Provides detailed error messages with remediation steps
- Supports partial cleanup and rollback procedures

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Interacts with**: All other WALLIX roles (can clean up resources created by any role)
- **Supports**: Complete WALLIX environment maintenance and lifecycle management
