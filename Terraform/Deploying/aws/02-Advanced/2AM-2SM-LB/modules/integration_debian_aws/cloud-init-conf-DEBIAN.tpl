#cloud-config
keyboard:
    layout: fr
users:
  - default
  - name: rdpuser
    lock_passwd: false
    plain_text_passwd: ${password_rdpuser}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys: ${ssh_key_public}
package_update: true
package_upgrade: true
packages:
- ansible
- firefox-esr
- geany
- git
- libegl1
- libglx0
- net-tools
- ncat
- terminator
- xauth
- xfce4
- xrdp

write_files:
  - path: /home/admin/.ssh/id_ed25519
    encoding: base64
    content: ${private_key}
    owner: 'admin:admin'
    permissions: '400'
    defer: true
  - path: /home/rdpuser/.ssh/id_ed25519
    encoding: base64
    content: ${private_key}
    owner: 'rdpuser:rdpuser'
    permissions: '400'
    defer: true