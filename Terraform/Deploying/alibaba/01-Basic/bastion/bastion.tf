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
#                           Bastion                            #
################################################################
data "alicloud_images" "bastion_image" {
  name_regex = "^bastion-${var.bastion_version}"
  owners     = "self"
}

data "alicloud_instance_types" "bastion_compute" {
  cpu_core_count       = var.bastion_cpu
  memory_size          = var.bastion_memory
  instance_type_family = var.bastion_instance_type
}

resource "alicloud_instance" "bastion" {
  instance_name = "bastion-${var.bastion_version}"
  instance_type = data.alicloud_instance_types.bastion_compute.instance_types.0.id

  image_id = data.alicloud_images.bastion_image.images.0.image_id

  resource_group_id = var.resource_group

  vswitch_id = data.alicloud_vswitches.default.vswitches.0.id

  security_groups = [
    data.alicloud_security_groups.default.groups.0.id
  ]

  internet_charge_type       = var.internet_charge_type
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  private_ip                 = var.bastion_private_ip

  system_disk_category = "cloud_auto"

  # cloud-init configuration
  user_data = <<EOT
#cloud-config

hostname: bastion-${var.bastion_version}
fqdn: bastion-${var.bastion_version}

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

  # Allow HTTP connections on bastion's public IP & update VM date to CET
  provisioner "remote-exec" {
    inline = [
      "echo -n 'http_host_trusted_hostnames = ${self.public_ip}' >> /var/wab/etc/wabengine.conf",
      "ntpdate -u pool.ntp.org"
    ]
  }
}

################################################################
#                          Public IPs                          #
################################################################
output "bastion_public_ip" {
  value      = alicloud_instance.bastion.public_ip
  depends_on = [alicloud_instance.bastion]
}
