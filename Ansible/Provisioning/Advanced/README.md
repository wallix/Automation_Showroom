# WALLIX Bastion Advanced Automation

Production-ready Ansible automation system for comprehensive WALLIX Bastion management. This system provides enterprise-grade infrastructure automation with full API integration, advanced security features, and operational safety mechanisms.

> **🚀 Framework Status**: This is an actively developed framework with new features, improvements, and learning content added regularly. The core functionality is production-ready and tested, but expect frequent updates with enhanced capabilities, better documentation, and additional examples to improve ease of use.

## Features

### Core Capabilities

- **Complete WALLIX API Integration**: Full support for WALLIX Bastion API v3.12
- **Multi-Environment Support**: Development, staging, and production configurations
- **Enterprise Security**: Vault integration, SSL verification, session management
- **Advanced Cleanup System**: Dependency-aware deletion with safety mechanisms
- **Production Validated**: Tested and validated on real WALLIX Bastion systems

### Supported Components

**Fully Implemented and Production Tested:**

- Authentication and session management
- User and user group management
- Device and service configuration
- Authorization and target group management
- Domain management (LDAP, AD, RADIUS)
- Advanced cleanup operations
- Configuration validation

**Framework Ready:**

- Application management
- Security policy management

## 🚀 Quick Start - Demo Mode

Get started in minutes with our interactive demo setup!

### Step 1: Automated Vault Setup

Use our interactive setup script to configure your WALLIX credentials:

```bash
# Navigate to the framework directory
cd Ansible/Provisioning/Advanced

# Run the automated vault setup
./scripts/setup-vault.sh
```

The script will:

- ✅ Prompt for your WALLIX Bastion credentials
- ✅ Create an encrypted Ansible vault
- ✅ Test API connectivity automatically
- ✅ Validate your configuration

### Step 2: Test Connectivity

Verify your setup with the built-in connection test:

```bash
# Test basic connectivity and authentication
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass
```

Expected output:

```
🎯 WALLIX Bastion API Connection Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Version Test: PASS ✅
🔐 Session Test: PASS ✅

Overall Status: ALL TESTS PASSED ✅
```

### Step 3: Run Demo Deployment

Execute the comprehensive demo playbook:

```bash
# Run the real deployment demo
ansible-playbook -i inventory/test playbooks/demo_provisionning.yml --ask-vault-pass
```

This demo will:

- 🔐 Authenticate with your WALLIX Bastion
- 🌐 Create demo global domains
- 🖥️ Set up demo devices and services
- 👥 Create demo users and groups
- 🔑 Configure authorizations and access
- 🧹 Clean up demo resources (optional)

### Alternative: Manual Vault Setup

If you prefer manual configuration:

```bash
# Create vault file manually
ansible-vault create group_vars/all/vault.yml

# Add your WALLIX credentials:
vault_wallix_bastion_url: "https://your-bastion-ip"
vault_wallix_username: "admin"  
vault_wallix_password: "your-secure-password"
```

## 📋 Prerequisites

- **Ansible**: 2.9+ (tested with Ansible 6.x)
- **Python**: 3.6+ with `requests` library
- **WALLIX Bastion**: API v3.12+ (tested on v12.0.15)
- **Network Access**: HTTPS connectivity to WALLIX Bastion API
- **Credentials**: Administrator access to WALLIX Bastion

## 🏗️ Advanced Setup

### Production Environment Setup

1. **Configure Production Inventory**

   ```bash
   # Copy and customize production inventory
   cp inventory/production.example inventory/production
   vim inventory/production
   ```

2. **Production Vault Configuration**

   ```bash
   # Create production vault with strong encryption
   ansible-vault create group_vars/all/vault.yml --vault-password-file .vault_pass
   
   # Configure production-grade settings
   vault_wallix_bastion_url: "https://bastion.company.com"
   vault_wallix_username: "automation_user"
   vault_wallix_password: "complex-secure-password"
   ```

3. **Deploy to Production**

   ```bash
   # Validate production configuration
   ansible-playbook -i inventory/production playbooks/test-connection.yml --ask-vault-pass
   
   # Run production deployment
   ansible-playbook -i inventory/production playbooks/demo_provisionning.yml \
     -e "deployment_environment=production" \
     --ask-vault-pass
   ```

## Architecture

### Role Structure

```text
roles/
├── wallix-auth/                # Authentication and session management
├── wallix-config/              # Base configuration management
├── wallix-domains/             # Domain and directory integration
├── wallix-users/               # User and group management
├── wallix-devices/             # Device and service management
├── wallix-authorizations/      # Authorization and access control
├── wallix-applications/        # Application management
├── wallix-policies/            # Security policy management
└── wallix-cleanup/             # Advanced cleanup operations
```

## 📚 Available Playbooks

### Core Playbooks

| Playbook | Purpose | Usage |
|----------|---------|-------|
| `test-connection.yml` | **Connection Testing** | Validate API connectivity and authentication |
| `demo_provisionning.yml` | **Demo Deployment** | Complete demo with all WALLIX components |
| `demo_cleanup_full.yml` | **Advanced Cleanup** | Comprehensive resource cleanup with safety |

### Usage Examples

```bash
# Test connectivity first
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass

# Run complete demo (creates and configures resources)
ansible-playbook -i inventory/production playbooks/demo_provisionning.yml --ask-vault-pass

# Clean up demo resources safely
ansible-playbook -i inventory/production playbooks/demo_cleanup_full.yml \
  -e "confirm_deletion=true" --ask-vault-pass

# Test specific components
ansible-playbook -i inventory/test playbooks/demo_provisionning.yml \
  --tags "auth,global-domains" --ask-vault-pass
```

### Playbook Tags

Use tags to run specific parts of the automation:

- `auth` - Authentication and session management
- `global-domains` - Global domain configuration  
- `devices` - Device and service setup
- `users` - User and group management
- `authorizations` - Access control configuration

## 🏗️ Architecture

### Role Structure

```text
roles/
├── wallix-auth/                # Authentication and session management
├── wallix-config/              # Base configuration management  
├── wallix-domains/             # Domain and directory integration
├── wallix-users/               # User and group management
├── wallix-devices/             # Device and service management
├── wallix-authorizations/      # Authorization and access control
├── wallix-applications/        # Application management
├── wallix-policies/            # Security policy management
└── wallix-cleanup/             # Advanced cleanup operations
```

## ⚙️ Configuration

### Environment Variables

```yaml
# group_vars/production.yml
wallix_auth:
  connection:
    verify_ssl: true
    timeout: 30
  session:
    max_session_duration: 3600

wallix_api:
  base_url: "https://your-bastion.example.com"
  version: "v3.12"

deployment_environment: "production"
```

### Security Configuration

```yaml
# Vault encrypted variables
vault_username: "admin"
vault_password: "secure-password"
vault_api_key: "optional-api-key"
vault_api_secret: "optional-api-secret"
```

## Advanced Features

### Cleanup System

The advanced cleanup system provides:

- **Dependency-Aware Deletion**: Automatic ordering to prevent constraint violations
- **Pattern-Based Filtering**: Include/exclude patterns for selective cleanup
- **Safety Mechanisms**: Backup before delete with confirmation prompts
- **Constraint Resolution**: Automatic handling of API constraint violations

```bash
# Full cleanup with pattern filtering
ansible-playbook -i inventory/development cleanup.yml \
  -e "cleanup_components={'devices': true, 'users': true}" \
  -e "deletion_filters={'include_patterns': ['test-*', 'dev-*']}" \
  -e "confirm_deletion=true" \
  --ask-vault-pass
```

### Multi-Component Deployment

```bash
# Deploy specific components only
ansible-playbook -i inventory/production deploy.yml \
  -e "components_to_manage={'users': true, 'devices': true}" \
  --ask-vault-pass
```

### Validation and Testing

```bash
# Syntax validation
ansible-playbook --syntax-check deploy.yml

# Dry run
ansible-playbook -i inventory/development deploy.yml \
  -e "operation_mode=dry_run" --check --diff

# Connectivity test
ansible-playbook -i inventory/development validate.yml --tags auth
```

## Production Readiness

### Validation Status

**Last Tested**: September 30, 2025  
**Environment**: WALLIX Bastion v12.0.15 (API v3.12)  
**Status**: PRODUCTION READY

**Test Results:**

- Authentication and session management: PASSED
- User and group management: PASSED
- Device and service configuration: PASSED
- Authorization management: PASSED
- Advanced cleanup operations: PASSED
- Multi-environment deployment: PASSED

### Security Features

- **Encrypted Secrets**: Ansible Vault integration
- **SSL Verification**: Production SSL certificate validation
- **Session Security**: Secure session management with automatic cleanup
- **Access Control**: Role-based access control implementation
- **Audit Trail**: Comprehensive logging and reporting

### Operational Safety

- **Backup Before Delete**: Automatic backup creation before destructive operations
- **Confirmation Prompts**: Required confirmations for production operations
- **Dependency Resolution**: Automatic handling of resource dependencies
- **Error Handling**: Comprehensive error handling with recovery procedures
- **Rollback Capability**: Built-in rollback mechanisms for failed deployments

## 🔧 Troubleshooting

### Quick Diagnostics

Use our built-in diagnostic tools for quick issue resolution:

```bash
# 1. Test basic connectivity
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass

# 2. Run setup script for configuration validation  
./scripts/setup-vault.sh

# 3. Test authentication only
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass --tags version

# 4. Test session creation
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass --tags session
```

### Common Issues & Solutions

#### 🔐 Authentication Problems

```bash
# Problem: "401 Unauthorized" or authentication failures
# Solution: Verify credentials and test connectivity

# Step 1: Check vault contents
ansible-vault view group_vars/all/vault.yml

# Step 2: Test with connection playbook
ansible-playbook -i inventory/test playbooks/test-connection.yml --ask-vault-pass -vvv

# Step 3: Verify WALLIX Bastion accessibility
curl -k https://your-bastion-ip/api/version
```

#### 🌐 Network Connectivity Issues

```bash
# Problem: Timeouts or connection refused
# Solution: Verify network access and firewall rules

# Test direct connectivity
curl -k -v https://your-bastion-ip/api/version

# Test with authentication
curl -k -u "username:password" https://your-bastion-ip/api/version
```

#### 🔒 SSL Certificate Problems

```bash
# Problem: SSL verification failures
# Solution: Configure SSL verification settings

# For testing environments (disable SSL verification)
ansible-playbook -i inventory/test playbooks/test-connection.yml \
  -e "api_config={'verify_ssl': false}" --ask-vault-pass

# For production (fix certificate issues)
# Update vault.yml with proper SSL settings
```

#### 🏗️ Playbook Execution Issues

```bash
# Problem: Playbook fails or behaves unexpectedly
# Solution: Use debug and validation modes

# Run in check mode (dry run)
ansible-playbook -i inventory/test playbooks/demo_provisionning.yml \
  --check --ask-vault-pass

# Run with verbose output
ansible-playbook -i inventory/test playbooks/demo_provisionning.yml \
  -vvv --ask-vault-pass

# Run specific tags only
ansible-playbook -i inventory/test playbooks/demo_provisionning.yml \
  --tags "auth" --ask-vault-pass
```

### Getting Help

1. **Use the connection test**: Always start with `playbooks/test-connection.yml`
2. **Check the setup script**: Run `./scripts/setup-vault.sh` for guided setup
3. **Review logs**: Enable verbose mode with `-vvv` for detailed logging
4. **Consult documentation**: Check the `docs/` directory for role-specific help

## 📖 Documentation & Resources

### Framework Documentation

- **[Setup Script Guide](scripts/README.md)**: Complete guide to automated setup
- **[Playbook Reference](playbooks/README.md)**: Detailed playbook documentation
- **[Role Documentation](docs/)**: Individual role guides and examples
- **[Status Report](STATUS_FINAL.md)**: Current implementation status

### Learning Resources

> 📚 **Learning Content**: We're continuously adding tutorials, examples, and best practices. Check back regularly for new learning materials and improved documentation.

### API References

- **WALLIX Bastion API**: v3.12 (tested on v12.0.15)
- **Ansible Requirements**: 2.9+ (tested with Ansible 6.x)
- **Python Dependencies**: `requests`, `urllib3`

## 🤝 Contributing & Support

### Contributing

This framework is actively developed with regular improvements:

- 🔄 **Regular Updates**: New features and improvements added frequently
- 📖 **Documentation**: Continuously improving guides and examples  
- 🧪 **Testing**: Expanding test coverage and validation scenarios
- 🎓 **Learning**: Adding tutorials and best practice guides

### Support Channels

- **Issues**: Create GitHub issues for bugs or feature requests
- **Documentation**: Check the comprehensive documentation in `docs/`
- **Examples**: Review playbook examples and role documentation
- **Community**: Join discussions and share improvements

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

---

> **⚠️ Important Note**: This automation framework is production-ready and has been validated with real WALLIX Bastion environments. However, as it's actively developed with frequent updates, always test new versions in a development environment before deploying to production.

**Last Updated**: October 3, 2025  
**Framework Version**: v2.0 (with enhanced QuickStart and diagnostics)  
**WALLIX Compatibility**: API v3.12, Bastion v12.0.15+
