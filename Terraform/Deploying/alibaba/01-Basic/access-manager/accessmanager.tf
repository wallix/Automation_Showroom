# Configure the Alicloud Provider
provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

data "alicloud_vpcs" "default" {
  vpc_name = var.vpc
}

data "alicloud_vswitches" "default" {
  vswitch_name = var.vswitch
}

data "alicloud_security_groups" "default" {
  vpc_id = data.alicloud_vpcs.default.vpcs.0.id
}

################################################################
#                        Access Manager                        #
################################################################
data "alicloud_images" "am_image" {
  name_regex = "^access-manager-${var.am_version}"
  owners     = "self"
}

data "alicloud_instance_types" "am_compute" {
  cpu_core_count       = var.am_cpu
  memory_size          = var.am_memory
  instance_type_family = var.am_instance_type
}

resource "alicloud_instance" "accessmanager" {
  instance_name = "access-manager-${var.am_version}"
  instance_type = data.alicloud_instance_types.am_compute.instance_types.0.id

  image_id = data.alicloud_images.am_image.images.0.image_id

  resource_group_id = var.resource_group

  vswitch_id = data.alicloud_vswitches.default.vswitches.0.id

  security_groups = [
    data.alicloud_security_groups.default.groups.0.id
  ]

  internet_charge_type       = var.internet_charge_type
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  private_ip                 = var.am_private_ip

  system_disk_category = "cloud_auto"

  # cloud-init configuration
  user_data = <<EOT
#cloud-config

hostname: access-manager-${var.am_version}
fqdn: access-manager-${var.am_version}

ssh_pwauth: true
manage_etc_hosts: true

apt:
  preserve_sources_list: true

users:
  - default
  - name: wabadmin
    lock_passwd: false
    hashed_passwd: ${var.wabadmin_password}
    ssh_authorized_keys:
      - ${var.ssh_key}
  - name: wabsuper
    lock_passwd: false
    hashed_passwd: ${var.wabsuper_password}
  - name: wabupgrade
    lock_passwd: false
    hashed_passwd: ${var.wabupgrade_password}
  - name: root
    ssh_authorized_keys:
      - ${var.ssh_key}
EOT

  connection {
    type        = "ssh"
    user        = "root"
    port        = 2242
    private_key = file(var.private_key_file)
    host        = self.public_ip
  }

  # Allow HTTP connections on access manager's public IP & update VM date to CET
  provisioner "remote-exec" {
    inline = [
      "echo -n 'http_host_trusted_hostnames = ${self.public_ip}' >> /var/wab/etc/wabengine.conf",
      "ntpdate -u pool.ntp.org"
    ]
  }
}

################################################################
#                          Public IP                          #
################################################################

output "am_public_ip" {
  value      = alicloud_instance.accessmanager.public_ip
  depends_on = [alicloud_instance.accessmanager]
}
