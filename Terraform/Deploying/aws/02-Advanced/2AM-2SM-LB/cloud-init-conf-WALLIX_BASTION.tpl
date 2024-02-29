#cloud-config

users:
  - name: wabadmin
    lock_passwd: false
    plain_text_passwd: ${wallix_password_wabadmin}
    ssh_authorized_keys:
      - ${wallix_sshkey}
  - name: wabsuper   
    lock_passwd: false
    plain_text_passwd: ${wallix_password_wabsuper}
    ssh_authorized_keys:
      - ${wallix_sshkey}
  - name: wabupgrade
    lock_passwd: false
    plain_text_passwd: ${wallix_password_wabupgrade}
    ssh_authorized_keys:
      - ${wallix_sshkey}
  - name: root
    ssh_authorized_keys:
      - ${wallix_sshkey} 
preserve_hostname: False
manage_etc_hosts: localhost