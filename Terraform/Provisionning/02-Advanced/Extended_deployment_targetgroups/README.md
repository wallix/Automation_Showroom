# WALLIX Bastion Extended Deployment

This Terraform configuration provides a comprehensive deployment solution for WALLIX Bastion using inventory files (YAML/JSON) to define users, devices, domains, and user groups.

## Features

- **Inventory-based Configuration**: Define your infrastructure using YAML or JSON inventory files
- **Basic Resource Management**: Supports domains, devices, users, and groups
- **Modular Design**: Easy to customize and extend
- **Best Practices**: Implements security best practices and proper resource dependencies
- **Production Ready**: Includes proper error handling, validation, and outputs

## Current Implementation Status

This implementation currently supports:
- ✅ Domains (password management domains)
- ✅ Devices (target servers/equipment)  
- ✅ Users (with basic authentication)
- ✅ User Groups (organizational grouping)

Future enhancements will include:
- 🔄 Device Accounts (specific accounts on devices)
- 🔄 Authorizations (user/group access permissions)
- 🔄 Advanced service configurations
- 🔄 Enhanced security policies

## Prerequisites

- Terraform >= 1.0
- WALLIX Bastion instance with API access
- Valid credentials for WALLIX Bastion API

## Directory Structure

```
Extended_deployment/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This documentation
└── inventory/                 # Inventory files directory
    ├── domains.yaml           # Domain definitions
    ├── devices.yaml           # Device/server definitions
    ├── users.yaml             # User definitions
    ├── accounts.yaml          # Device account definitions
    └── groups.yaml            # User group definitions
```

## Quick Start

1. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your WALLIX Bastion details:
   ```hcl
   bastion_ip       = "your-bastion-ip"
   bastion_user     = "admin"
   bastion_password = "your-password"
   bastion_port     = 443
   ```

3. **Review and customize inventory files** in the `inventory/` directory

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan the deployment**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Inventory Files

### domains.yaml
Defines password management domains:
```yaml
domains:
  - domain_name: "windows_domain"
    description: "Windows Active Directory Domain"
    enable_password_change: true
    admin_account:
      account_login: "domain_admin"
      account_name: "Domain Administrator"
```

### devices.yaml
Defines target devices and their services:
```yaml
devices:
  - device_name: "web-server-01"
    host: "192.168.1.10"
    description: "Production Web Server #1"
    services:
      - id: "ssh"
        port: 22
        protocol: "SSH"
        service_name: "SSH Access"
```

### users.yaml
Defines users and their direct authorizations:
```yaml
users:
  - user_name: "john.doe"
    display_name: "John Doe"
    email: "john.doe@company.com"
    profile: "user"
    groups: ["developers"]
    authorizations:
      - device_name: "web-server-01"
        account_name: "webadmin"
        services: ["ssh"]
```

### accounts.yaml
Defines accounts on devices:
```yaml
accounts:
  - device_name: "web-server-01"
    account_name: "webadmin"
    account_login: "webadmin"
    description: "Web server administrator account"
    domain_name: "linux_domain"
    credentials:
      password: "WebAdmin123!"
```

### groups.yaml
Defines user groups and their authorizations:
```yaml
groups:
  - group_name: "developers"
    description: "Development Team"
    timeframes: ["business_hours"]
    authorizations:
      - device_name: "web-server-01"
        account_name: "webadmin"
        services: ["ssh"]
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `bastion_ip` | IP address of WALLIX Bastion | - | Yes |
| `bastion_user` | API username | `"admin"` | No |
| `bastion_password` | API password | - | Yes |
| `bastion_port` | API port | `443` | No |
| `inventory_format` | Format of inventory files | `"yaml"` | No |
| `default_user_profile` | Default user profile | `"user"` | No |

## Outputs

The configuration provides detailed outputs for all created resources:

- `domains`: Created domains with IDs and details
- `devices`: Created devices with IDs and details
- `users`: Created users (sensitive output)
- `accounts`: Created accounts (sensitive output)
- `authorizations`: Created authorizations
- `summary`: Deployment summary with counts

## Best Practices

### Security
- Store sensitive variables in environment variables or secure storage
- Use strong passwords and enable password rotation
- Implement proper IP restrictions
- Enable session recording for compliance

### Organization
- Use descriptive names for all resources
- Group related resources logically
- Document your inventory files
- Use version control for inventory files

### Operations
- Test in development environment first
- Use Terraform workspaces for different environments
- Implement proper backup procedures
- Monitor resource drift

## Advanced Configuration

### Custom Timeframes
Define timeframes in your WALLIX Bastion configuration:
- `business_hours`: Monday-Friday 8AM-6PM
- `24x7`: Always available
- `business_hours_extended`: Monday-Friday 7AM-9PM

### Connection Policies
Configure connection policies for enhanced security:
- `RDP_RESTRICTION`: Restrict RDP clipboard and file transfer
- `TELNET_RESTRICTION`: Restrict telnet commands

### User Restrictions
Available user restrictions:
- `no_password_checkout`: Prevent password checkout
- `session_recording_required`: Enforce session recording
- `approval_required`: Require approval for access
- `read_only_access`: Limit to read-only operations

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify bastion IP, username, and password
   - Check network connectivity to WALLIX Bastion

2. **Resource Dependencies**
   - Ensure domains are created before accounts reference them
   - Verify device names match between inventory files

3. **Invalid Inventory Format**
   - Validate YAML syntax using online validators
   - Check for proper indentation and structure

### Debug Mode
Enable Terraform debug logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

## Contributing

1. Follow the existing code structure
2. Update documentation for new features
3. Test changes in development environment
4. Follow semantic versioning for releases

## Support

For issues and questions:
- Check the [WALLIX Bastion Terraform Provider documentation](https://registry.terraform.io/providers/wallix/wallix-bastion/latest)
- Review WALLIX Bastion API documentation
- Contact your WALLIX support team

## License

This configuration is provided as-is for demonstration and production use. Ensure compliance with your organization's security policies.