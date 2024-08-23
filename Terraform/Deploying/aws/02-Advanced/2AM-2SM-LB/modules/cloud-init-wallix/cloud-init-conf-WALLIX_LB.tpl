#cloud-config
runcmd:
  - [ sh, -xc, "sed -i -e '$ahttp_host_trusted_hostnames=${http_host_trusted_hostnames}' /var/wab/etc/wabengine.conf" ]
  - [ sh, -xc, "WABVersion | grep Bastion || sed -i -e '$aweb.check.session.origin=false' /var/wab/etc/wabam/wabam.properties" ]