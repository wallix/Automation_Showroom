# WALLIX Devices Management Role

## Overview

The `wallix-devices` role manages physical and virtual devices (servers, workstations, network equipment) in WALLIX Bastion, including their services and accounts.

## Purpose

- Create and manage target devices
- Configure device services (SSH, RDP, HTTP, etc.)
- Manage device-specific accounts
- Set up device connectivity settings

## Dependencies

### Required Roles

- **wallix-auth** - Must be executed first for authentication

### Required Variables

- `wallix_session_cookie` - Provided by wallix-auth role
- `wallix_devices` - List of devices to manage

### Optional Variables

- `wallix_device_services` - Services configuration for devices
- `wallix_accounts` - Account management for devices

## Usage

### Basic Device Creation

```yaml
- name: Create WALLIX devices
  include_role:
    name: wallix-devices
  vars:
    wallix_devices:
      - name: "web-server-01"
        host: "10.0.1.100"
        description: "Production web server"
        type: "server"
        state: "present"
      - name: "db-server-01"
        host: "10.0.1.200"
        description: "Database server"
        type: "server"
        state: "present"
```

### Complete Device Configuration

```yaml
- name: Manage devices with services
  include_role:
    name: wallix-devices
  vars:
    wallix_devices:
      - name: "web-server-01"
        host: "10.0.1.100"
        description: "Production web server"
        type: "server"
        domain: "production"
        state: "present"
    
    wallix_device_services:
      - name: "web-ssh"
        device_name: "web-server-01"
        protocol: "SSH"
        port: 22
        connection_policy: "default"
        state: "present"
      - name: "web-http"
        device_name: "web-server-01"
        protocol: "HTTP"
        port: 80
        state: "present"
```

## Configuration Options

### Device Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique device name |
| `host` | Yes | IP address or hostname |
| `description` | No | Device description |
| `type` | No | Device type (server, workstation, network) |
| `domain` | No | Target domain for the device |
| `state` | No | present/absent (default: present) |

### Service Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Service name |
| `device_name` | Yes | Associated device name |
| `protocol` | Yes | Protocol (SSH, RDP, HTTP, HTTPS, etc.) |
| `port` | Yes | Service port number |
| `connection_policy` | No | Connection policy name |
| `state` | No | present/absent (default: present) |

## Supported Protocols

- SSH (port 22)
- RDP (port 3389)
- HTTP (port 80)
- HTTPS (port 443)
- Telnet (port 23)
- VNC (port 5900)
- Custom protocols with specified ports

## Examples

### Multiple Devices with Different Types

```yaml
wallix_devices:
  - name: "linux-server-01"
    host: "192.168.1.10"
    description: "Linux production server"
    type: "server"
    domain: "production"
  
  - name: "windows-workstation-01"
    host: "192.168.1.50"
    description: "Windows admin workstation"
    type: "workstation"
    domain: "office"
  
  - name: "cisco-switch-01"
    host: "192.168.1.1"
    description: "Core network switch"
    type: "network"
    domain: "infrastructure"
```

### Services Configuration

```yaml
wallix_device_services:
  - name: "linux-ssh"
    device_name: "linux-server-01"
    protocol: "SSH"
    port: 22
    connection_policy: "ssh_policy"
  
  - name: "windows-rdp"
    device_name: "windows-workstation-01"
    protocol: "RDP"
    port: 3389
    connection_policy: "rdp_policy"
  
  - name: "switch-telnet"
    device_name: "cisco-switch-01"
    protocol: "Telnet"
    port: 23
    connection_policy: "network_policy"
```

## Outputs

After execution, provides:

- `device_creation_results` - Results of device creation
- `service_configuration_results` - Service configuration results
- `device_count` - Number of devices processed

## Error Handling

- Validates device parameters before creation
- Checks for duplicate device names
- Verifies protocol/port combinations
- Provides detailed error messages for failed operations

## Dependencies on Other Roles

- **Depends on**: wallix-auth (authentication)
- **Used by**: wallix-authorizations (device access), wallix-global-accounts (device accounts)
- **Related**: wallix-domains (device domains), wallix-users (user access)
