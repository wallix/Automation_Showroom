## Generate Firefox bookmarks for AM and SM instances
# This will create HTML files that can be used as bookmarks on the Debian admin instance
# Each bookmark will link to the respective AM or SM instance's private IP address


resource "local_file" "firefox_bookmark_am" {
  count    = length(module.instance_access_manager[*].instance_private_ip)
  content  = <<-EOT
        <!DOCTYPE html>
        <html>
            <head>
                <title>AM Instance ${count.index + 1} Bookmark</title>
            </head>
            <body>
                <a href="https://${module.instance_access_manager[count.index].instance_private_ip}">AM Instance ${count.index + 1}</a>
            </body>
        </html>
    EOT
  filename = "${path.module}/generated_files/am_instance_${count.index + 1}_bookmark.html"
}

resource "local_file" "firefox_bookmark_sm" {
  count    = length(module.instance_bastion[*].instance_private_ip)
  content  = <<-EOT
        <!DOCTYPE html>
        <html>
            <head>
                <title>SM Instance ${count.index + 1} Bookmark</title>
            </head>
            <body>
                <a href="https://${module.instance_bastion[count.index].instance_private_ip}">SM Instance ${count.index + 1}</a>
            </body>
        </html>
    EOT
  filename = "${path.module}/generated_files/sm_instance_${count.index + 1}_bookmark.html"
}

# The bookmarks will be placed on the desktop of the Debian admin instance for easy access
resource "ssh_resource" "copy_bookmarks" {
  count       = length(module.integration_debian) > 0 ? 1 : 0
  when        = "create"
  host        = module.integration_debian[0].public_ip_debian_admin
  user        = "rdpuser"
  private_key = local_sensitive_file.private_key.content
  timeout     = "15m"
  retry_delay = "5s"

  pre_commands = [
    "mkdir -p /home/rdpuser/Desktop"
  ]

  dynamic "file" {
    for_each = local_file.firefox_bookmark_am
    content {
      source      = file.value.filename
      destination = "/home/rdpuser/Desktop/${basename(file.value.filename)}"
      permissions = "0666"
    }
  }

  dynamic "file" {
    for_each = local_file.firefox_bookmark_sm
    content {
      source      = file.value.filename
      destination = "/home/rdpuser/Desktop/${basename(file.value.filename)}"
      permissions = "0640"
    }
  }

  depends_on = [
    local_file.firefox_bookmark_am,
    local_file.firefox_bookmark_sm
  ]
}

# Push the info_replication.txt file to the bastion host using integration_debian as a bastion host
# This file contains the information needed to set up replication between Bastion hosts
resource "ssh_resource" "info_replication" {
  count = var.number_of_sm == 2 && length(module.integration_debian) > 0 ? 1 : 0

  when = "create"

  host                = module.instance_bastion[0].instance_private_ip
  user                = "wabadmin"
  port                = "2242"
  bastion_host        = module.integration_debian[0].public_ip_debian_admin
  bastion_user        = "rdpuser"
  bastion_port        = "22"
  bastion_private_key = local_sensitive_file.private_key.content

  private_key = local_sensitive_file.private_key.content
  # Try to complete in at most 15 minutes and wait 5 seconds between retries
  timeout     = "15m"
  retry_delay = "5s"

  file {
    # source      = "${path.module}/generated_files/info_replication.txt"
    content     = length(local_sensitive_file.replication_master) > 0 ? local_sensitive_file.replication_master[0].content : ""
    destination = "/home/wabadmin/info_replication.txt"
    permissions = "0640"
  }

}