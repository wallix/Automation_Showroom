# WALLIX Authentication Role

## Overview

The `wallix-auth` role handles authentication to WALLIX Bastion systems via API. It supports both credential-based and API key authentication methods, manages session cookies, and validates connectivity.

## Purpose

- Authenticate to WALLIX Bastion API
- Manage session cookies for persistent connections
- Validate API connectivity and credentials
- Provide foundation for other WALLIX operations

## Dependencies

### Required Variables

- `vault_wallix_username` - WALLIX username (stored in vault)
- `vault_wallix_password` - WALLIX password (stored in vault)
- `vault_wallix_bastion_url` - WALLIX Bastion URL

### Optional Variables

- `vault_api_key` - API key for API-based authentication
- `vault_api_secret` - API secret for API-based authentication

### Role Dependencies

- **None** - This is a foundational role
- **Required by**: All other WALLIX roles depend on this for authentication

## Usage

### Basic Usage

```yaml
- name: Authenticate to WALLIX
  include_role:
    name: wallix-auth
  vars:
    wallix_auth:
      initial_auth_method: "credentials"
      credentials:
        username: "{{ vault_wallix_username }}"
        password: "{{ vault_wallix_password }}"
      connection:
        verify_ssl: false
        timeout: 30
    wallix_api:
      base_url: "{{ vault_wallix_bastion_url }}:443/api"
```

### Advanced Configuration

```yaml
- name: Authenticate with API key
  include_role:
    name: wallix-auth
  vars:
    wallix_auth:
      initial_auth_method: "api_key"
      api_key:
        key: "{{ vault_api_key }}"
        secret: "{{ vault_api_secret }}"
      session:
        use_cookie: true
        auto_renew: true
        max_session_duration: 3600
      connection:
        verify_ssl: true
        timeout: 30
        retry_count: 3
```

## Configuration Options

### Authentication Methods

| Method | Description | Required Variables |
|--------|-------------|-------------------|
| `credentials` | Username/password authentication | `username`, `password` |
| `api_key` | API key authentication | `key`, `secret` |

### Session Management

| Parameter | Default | Description |
|-----------|---------|-------------|
| `use_cookie` | `true` | Enable session cookie persistence |
| `auto_renew` | `true` | Automatically renew sessions |
| `max_session_duration` | `3600` | Maximum session duration (seconds) |
| `cleanup_on_exit` | `true` | Clean up session on completion |

### Connection Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `verify_ssl` | `true` | Verify SSL certificates |
| `timeout` | `30` | Connection timeout (seconds) |
| `retry_count` | `3` | Number of retry attempts |
| `retry_delay` | `5` | Delay between retries (seconds) |

## Outputs

After successful execution, this role provides:

- `wallix_session_cookie` - Session cookie for subsequent API calls
- `wallix_auth_status` - Authentication status
- `wallix_api_version` - WALLIX API version
- `wallix_connectivity_status` - Connectivity validation result

## Examples

### Minimal Setup

```yaml
tasks:
  - include_role:
      name: wallix-auth
    vars:
      wallix_auth:
        credentials:
          username: "admin"
          password: "{{ vault_password }}"
      wallix_api:
        base_url: "https://wallix.example.com:443/api"
```

### Production Setup

```yaml
tasks:
  - include_role:
      name: wallix-auth
    vars:
      wallix_auth:
        initial_auth_method: "credentials"
        credentials:
          username: "{{ vault_wallix_username }}"
          password: "{{ vault_wallix_password }}"
        session:
          use_cookie: true
          auto_renew: true
          renewal_threshold: 300
          max_session_duration: 3600
        connection:
          verify_ssl: true
          timeout: 30
          retry_count: 3
          retry_delay: 5
      wallix_api:
        base_url: "{{ vault_wallix_bastion_url }}:443/api"
        headers:
          Content-Type: "application/json"
          Accept: "application/json"
```

## Error Handling

- Validates authentication configuration before attempting connection
- Provides detailed error messages for common issues
- Supports retry mechanisms for transient failures
- Cleans up resources on failure

## Security Considerations

- Always use vault-encrypted variables for credentials
- Enable SSL verification in production environments
- Use API keys instead of passwords when possible
- Implement proper session timeout policies

## Troubleshooting

Common issues and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid authentication configuration` | Missing credentials | Ensure username and password are defined |
| `SSL certificate verify failed` | Self-signed certificates | Set `verify_ssl: false` for testing |
| `Connection timeout` | Network issues | Increase timeout value |
| `Authentication failed` | Invalid credentials | Verify vault variables |
