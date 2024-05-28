#cloud-config
users:
  - default
  - name: rdpuser
    lock_passwd: false
    plain_text_passwd: ${password_rdpuser}
package_update: true
package_upgrade: true
packages:
- firefox-esr
- xauth
- libegl1 
- libglx0
- xfce4
- xrdp