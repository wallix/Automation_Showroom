# WALLIX Bastion Provisioning - Basic Configuration

This Ansible playbook provides a very basic example for initial WALLIX Bastion provisioning, demonstrating simple user and device creation.

## Overview

This automation solution allows you to:

- Authenticate with the WALLIX Bastion API
- Create multiple users with their credentials
- Add target devices to be managed via the Bastion

## File Structure

```text
├── api_creds.yml              # API authentication information
├── devices_to_create.yml      # List of devices to create
├── group_vars/
│   └── bastions.yml           # Bastion-specific variables
├── hosts                      # Ansible inventory file
├── playbook.yml               # Main playbook
├── roles/
│   ├── bastion-auth/          # Role for API authentication
│   ├── devices/               # Role for creating devices
│   └── users/                 # Role for creating users
└── users_to_create.yml        # List of users to create
```

## Prerequisites

| Component      | Requirement                                    |
| -------------- | ---------------------------------------------- |
| Ansible        | ≥ 2.15                                         |
| Python         | ≥ 3.9                                          |
| WALLIX Bastion | ≥ 10.0 (deployed and accessible)               |
| API Access     | Account with API permissions on target Bastion |

## Configuration

### 1. Define API Authentication Information

Edit the `api_creds.yml` file with your Bastion details:

```yaml
bastion_url: "https://your-bastion.domain/api"
api_user: "your_api_user"
api_password: "your_api_password"
```

### 2. Configure Host Inventory

Edit the `hosts` file to point to your Bastion:

```ini
[bastions]
ip_address_or_domain_name:ssh_port
```

For example: `192.168.1.100:22`

### 3. Define Users to Create

Edit the `users_to_create.yml` file to specify the users to create:

```yaml
users:
    - { user_name: "user1", user_email: "user1@domain.com", user_password: "Password1" }
    - { user_name: "user2", user_email: "user2@domain.com", user_password: "Password2" }
```

### 4. Define Devices to Create

Edit the `devices_to_create.yml` file to specify the devices to add:

```yaml
devices:
    - { device_name: "server1", device_host: "192.168.1.101" }
    - { device_name: "server2", device_host: "192.168.1.102" }
```

## Running the Playbook

Execute the playbook from this directory:

```bash
ansible-playbook -i hosts playbook.yml
```

### Expected Output

```text
PLAY [Provision WALLIX Bastion] ************************************************

TASK [bastion-auth : Authenticate with API] ************************************
ok: [192.168.1.100]

TASK [users : Create users] ****************************************************
changed: [192.168.1.100] => (item=user1)
changed: [192.168.1.100] => (item=user2)

TASK [devices : Create devices] ************************************************
changed: [192.168.1.100] => (item=server1)
changed: [192.168.1.100] => (item=server2)

PLAY RECAP *********************************************************************
192.168.1.100    : ok=3    changed=2    unreachable=0    failed=0
```

## Security

**Important**: Configuration files contain sensitive information:

- User passwords in `users_to_create.yml`
- API credentials in `api_creds.yml`

For a production environment:

- Use Ansible Vault to encrypt these files: `ansible-vault encrypt api_creds.yml users_to_create.yml`
- Or store sensitive information in an external secrets manager

## Customization

### Add Additional User Attributes

Edit `roles/users/tasks/main.yml` to add extra attributes according to the WALLIX API documentation.

### Configure Devices with Advanced Attributes

Edit `roles/devices/tasks/main.yml` to add more complex device configurations.

## Troubleshooting

### Check API Connection

If the playbook fails to connect to the API, check:

- The Bastion URL in `api_creds.yml`
- The API credentials in `api_creds.yml`
- Bastion accessibility from the Ansible server

### Common Error Messages

- **Error 401**: API authentication issue
- **Error 400**: Incorrect request format
- **Error 409**: Conflict (user or device already exists)

## License

Please refer to the LICENSE file at the root of the project for license information.

## Requirements

| Name           | Version |
| -------------- | ------- |
| ansible-core   | ≥ 2.15  |
| Python         | ≥ 3.9   |
| WALLIX Bastion | ≥ 10.0  |

## See Also

- [WALLIX Ansible Collection](../../wallix-ansible-collection/README.md) - Production-ready collection
- [Provisioning](../../provisioning/README.md) - Advanced provisioning patterns
- [WALLIX API Documentation](https://www.wallix.com/support/documentation/)
