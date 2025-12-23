# Role: wallix-connection-policies

## Description

This role manages **connection policies** in WALLIX Bastion. Connection policies define rules and options for connection sessions based on protocols (SSH, RDP, etc.).

## Requirements

- `wallix-auth` role must be executed first to establish authentication
- Valid session cookie (`wallix_session_cookie`)
- Accessible WALLIX Bastion API

## Variables

### Variables principales

```yaml
wallix_connection_policies:
  - connection_policy_name: "SSH_Standard"
    description: "Standard SSH connection policy"
    protocol: "SSH"
    options:
      recording: true
      session_sharing: false
    subprotocols:
      - "SSH_SHELL_SESSION"
      - "SFTP_SESSION"
```

### Supported Protocols

- **SSH**: Secure Shell
- **RDP**: Remote Desktop Protocol
- **TELNET**: Telnet protocol
- **VNC**: Virtual Network Computing
- **HTTP**: Web protocols

### Common Options

- **recording**: Session recording (true/false)
- **session_sharing**: Session sharing (true/false)
- **clipboard**: Clipboard management ("up", "down", "both", "none")
- **file_transfer**: File transfer (true/false)

## Examples

### Create standard connection policies

```yaml
- hosts: localhost
  roles:
    - wallix-auth
    - wallix-connection-policies
  vars:
    wallix_connection_policies:
      - connection_policy_name: "SSH_Standard"
        description: "Standard SSH policy with recording"
        protocol: "SSH"
        options:
          recording: true
          session_sharing: false
        subprotocols:
          - "SSH_SHELL_SESSION"
          - "SFTP_SESSION"
      
      - connection_policy_name: "RDP_Standard"
        description: "Standard RDP policy"
        protocol: "RDP"
        options:
          recording: true
          clipboard: "up"
          file_transfer: true
        subprotocols:
          - "RDP_REMOTE_APP"
          - "RDP_DESKTOP"
```

### List existing connection policies

```yaml
- hosts: localhost
  roles:
    - wallix-auth
    - wallix-connection-policies
  vars:
    wallix_connection_policies_list: true
```

## Sub-protocols by Protocol

### SSH

- `SSH_SHELL_SESSION` - Session shell SSH
- `SFTP_SESSION` - Transfert de fichiers SFTP
- `SCP_UP` - Upload SCP
- `SCP_DOWN` - Download SCP

### RDP

- `RDP_DESKTOP` - Bureau distant RDP
- `RDP_REMOTE_APP` - Application distante RDP
- `RDP_CLIPBOARD_UP` - Presse-papier vers le serveur
- `RDP_CLIPBOARD_DOWN` - Presse-papier depuis le serveur

### HTTP/HTTPS

- `HTTP_BROWSER` - Navigation web
- `HTTPS_BROWSER` - Navigation web sécurisée

## API Endpoints

- **GET** `/api/sessionrights` - List all connection policies
- **POST** `/api/sessionrights` - Create a new connection policy
- **GET** `/api/sessionrights/{id}` - Retrieve a specific connection policy
- **PUT** `/api/sessionrights/{id}` - Update a connection policy
- **DELETE** `/api/sessionrights/{id}` - Delete a connection policy

## Tasks

- `create_connection_policies.yml` - Connection policy creation
- `list_connection_policies.yml` - Connection policy listing

## API Return Codes

- **200/201/204**: Connection policy successfully created
- **409**: Connection policy already exists
- **404**: Connection policy not found (during deletion)

## Dependencies

- `wallix-auth` - For authentication
- `wallix-cleanup` - For cleanup (optional)
