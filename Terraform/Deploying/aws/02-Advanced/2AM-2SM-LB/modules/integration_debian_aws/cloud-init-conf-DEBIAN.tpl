#cloud-config
keyboard:
    layout: fr
users:
  - default
  - name: rdpuser
    lock_passwd: false
    plain_text_passwd: ${password_rdpuser}
    shell: /bin/bash
package_update: true
package_upgrade: true
packages:
- firefox-esr
- xauth
- libegl1
- libglx0
- xfce4
- xrdp

write_files:
  - path: /home/admin/.ssh/id_ed25519
    encoding: base64
    content: ${private_key}
    owner: 'admin:admin'
    permissions: '400'
    defer: true