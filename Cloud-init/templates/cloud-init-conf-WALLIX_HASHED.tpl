#cloud-config
hostname: {hostname}
fqdn: {fqdn}

# Set passwords for WALLIX service users using secure hashes
chpasswd:
    users:
        - name: wabadmin
          password: {wabadmin_password_hash}
          type: hash
        - name: wabsuper
          password: {wabsuper_password_hash}
          type: hash
        - name: wabupgrade
          password: {wabupgrade_password_hash}
          type: hash
    expire: False

# Enable password authentication via SSH
ssh_pwauth: true
manage_etc_hosts: {manage_etc_hosts}
{preserve_sources_section}
{bootcmd_section}
{additional_config_section}

# Inject scripts if needed
{write_files_section}

# Run scripts after boot
{runcmd_section}