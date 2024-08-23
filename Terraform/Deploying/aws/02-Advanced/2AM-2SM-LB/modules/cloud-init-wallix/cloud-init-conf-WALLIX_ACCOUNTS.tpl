#cloud-config

chpasswd:
  list: |
    wabadmin:${wabadmin_password}
    wabsuper:${wabsuper_password}
    wabupgrade:${wabupgrade_password}
  expire: False