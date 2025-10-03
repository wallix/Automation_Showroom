# WALLIX Authorizations Management Role

## Overview

The `wallix-authorizations` role manages access authorizations in WALLIX Bastion, defining which users or groups can access specific devices and services.

## Purpose

- Create and manage access authorizations
- Configure target groups for device access
- Define user/group permissions
- Set up time-based access restrictions

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication
- **wallix-users** - Should be executed before to create users
- **wallix-devices** - Should be executed before to create devices

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_authorizations` - List of authorizations to create

### Optional Variables

- `wallix_target_groups` - Target groups configuration
- `wallix_authorizations_mode` - Operation mode

## Usage

### Basic Authorization Setup

```yaml
- name: Create access authorizations
  include_role:
    name: wallix-authorizations
  vars:
    wallix_target_groups:
      - name: "web-servers"
        description: "Web server group"
        devices: ["web-server-01", "web-server-02"]
    
    wallix_authorizations:
      - name: "admin-web-access"
        description: "Admin access to web servers"
        user_group: "administrators"
        target_group: "web-servers"
        protocols: ["SSH"]
        time_restrictions: []
```

### Complete Authorization Configuration

```yaml
- name: Comprehensive authorization setup
  include_role:
    name: wallix-authorizations
  vars:
    wallix_target_groups:
      - name: "database-servers"
        description: "Database server group"
        devices: ["db-server-01", "db-server-02"]
        services: ["db-ssh", "db-mysql"]
      - name: "application-servers"
        description: "Application server group"
        devices: ["app-server-01", "app-server-02"]
        services: ["app-ssh", "app-http"]
    
    wallix_authorizations:
      - name: "dba-database-access"
        description: "DBA access to database servers"
        user_group: "database-admins"
        target_group: "database-servers"
        protocols: ["SSH", "MySQL"]
        account: "oracle"
        time_restrictions:
          - days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
            hours: "08:00-18:00"
        approval_required: false
      
      - name: "dev-app-access"
        description: "Developer access to application servers"
        user_group: "developers"
        target_group: "application-servers"
        protocols: ["SSH"]
        account: "deploy"
        time_restrictions:
          - days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
            hours: "09:00-17:00"
        approval_required: true
        approver_group: "team-leads"
```

## Configuration Options

### Authorization Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique authorization name |
| `description` | No | Authorization description |
| `user_group` | Yes | User group with access |
| `target_group` | Yes | Target group to access |
| `protocols` | Yes | Allowed protocols |
| `account` | No | Specific account to use |
| `time_restrictions` | No | Time-based access restrictions |
| `approval_required` | No | Require approval for access |
| `state` | No | present/absent (default: present) |

### Target Group Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Target group name |
| `description` | No | Group description |
| `devices` | Yes | List of device names |
| `services` | No | List of service names |
| `state` | No | present/absent (default: present) |

### Time Restriction Format

| Parameter | Description |
|-----------|-------------|
| `days` | List of allowed days (monday, tuesday, etc.) |
| `hours` | Time range in HH:MM-HH:MM format |
| `timezone` | Timezone for time restrictions |

## Supported Protocols

- **SSH** - Secure Shell access
- **RDP** - Remote Desktop Protocol
- **HTTP/HTTPS** - Web access
- **Telnet** - Telnet access
- **VNC** - Virtual Network Computing
- **MySQL** - MySQL database access
- **PostgreSQL** - PostgreSQL database access
- **Oracle** - Oracle database access

## Examples

### Role-Based Access

```yaml
wallix_target_groups:
  - name: "production-servers"
    description: "All production servers"
    devices: ["web-prod-01", "app-prod-01", "db-prod-01"]
  
  - name: "development-servers"
    description: "Development environment"
    devices: ["web-dev-01", "app-dev-01", "db-dev-01"]

wallix_authorizations:
  - name: "admin-prod-access"
    description: "Admin access to production"
    user_group: "production-admins"
    target_group: "production-servers"
    protocols: ["SSH", "RDP"]
    account: "admin"
    time_restrictions:
      - days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
        hours: "08:00-20:00"
    approval_required: true
    approver_group: "security-team"
  
  - name: "dev-dev-access"
    description: "Developer access to development"
    user_group: "developers"
    target_group: "development-servers"
    protocols: ["SSH"]
    account: "developer"
    approval_required: false
```

### Service-Specific Access

```yaml
wallix_target_groups:
  - name: "web-services"
    description: "Web services group"
    devices: ["web-server-01"]
    services: ["web-ssh", "web-http", "web-https"]

wallix_authorizations:
  - name: "webmaster-access"
    description: "Webmaster access to web services"
    user_group: "webmasters"
    target_group: "web-services"
    protocols: ["SSH", "HTTP", "HTTPS"]
    account: "webadmin"
    time_restrictions: []
    approval_required: false
```

### Emergency Access

```yaml
wallix_authorizations:
  - name: "emergency-access"
    description: "Emergency access to all systems"
    user_group: "emergency-responders"
    target_group: "all-systems"
    protocols: ["SSH", "RDP"]
    account: "emergency"
    time_restrictions: []
    approval_required: true
    approver_group: "security-officers"
    emergency_access: true
    max_session_duration: 3600
```

### Time-Restricted Access

```yaml
wallix_authorizations:
  - name: "contractor-access"
    description: "Contractor access during business hours"
    user_group: "contractors"
    target_group: "contractor-systems"
    protocols: ["SSH"]
    account: "contractor"
    time_restrictions:
      - days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
        hours: "09:00-17:00"
        timezone: "UTC"
    approval_required: true
    approver_group: "project-managers"
    valid_from: "2024-01-01"
    valid_until: "2024-12-31"
```

## Approval Workflow

When `approval_required` is enabled:

1. User requests access through WALLIX interface
2. Approval request sent to approver group
3. Approver reviews and approves/denies request
4. User gains access upon approval
5. Access is logged and audited

## Time Restrictions

Configure when users can access systems:

- **Business hours only**: Restrict to working hours
- **Weekdays only**: Block weekend access
- **Maintenance windows**: Allow access during specific periods
- **Emergency exceptions**: Override restrictions for emergencies

## Operation Modes

- **normal** - Standard operation mode
- **dry_run** - Validate without making changes
- **validate_only** - Only validate configuration

## Outputs

After execution, provides:

- `authorization_creation_results` - Authorization setup results
- `target_group_results` - Target group creation results
- `validation_results` - Configuration validation results

## Security Features

### Access Control

- User/group-based permissions
- Device/service-specific access
- Protocol restrictions
- Account limitations

### Audit and Compliance

- Complete access logging
- Approval workflows
- Time-based restrictions
- Session recording

### Emergency Procedures

- Emergency access provisions
- Override capabilities
- Escalation procedures
- Rapid revocation

## Error Handling

- Validates user and device existence before creating authorizations
- Checks for duplicate authorization names
- Verifies time restriction formats
- Provides detailed error messages for configuration issues

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication), wallix-users (user creation), wallix-devices (device creation)
- **Uses**: wallix-global-accounts (account access), wallix-domains (domain-based access)
- **Related**: wallix-config (policy configuration), wallix-cleanup (authorization cleanup)
