# WALLIX Cloud-Init Generator

A portable Python script for generating cloud-init configurations for WALLIX Access Manager and Session Manager.
Supports NoCloud datasource for major hypervisors and cloud platforms.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Cloud-Init & NoCloud Overview](#cloud-init--nocloud-overview)
- [Hypervisor Configuration](#hypervisor-configuration)
  - [VMware vSphere/ESXi](#vmware-vsphereesxi)
  - [Proxmox VE](#proxmox-ve)
  - [KVM/QEMU](#kvmqemu)
  - [Hyper-V](#hyper-v)
  - [VirtualBox](#virtualbox)
- [Usage Examples](#usage-examples)
- [Network Configuration](#network-configuration)
- [Generated Files](#generated-files)
- [Integration](#integration)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Features

- **Secure Password Generation** - Cryptographically secure passwords for all WALLIX service accounts
- **Multipart Cloud-Init** - Conditional sections for flexible deployment
- **Network Configuration** - Full network-config support for NoCloud datasource
- **Advanced Networking** - Static IP, DHCP, bonding, VLANs, multiple interfaces
- **Load Balancer Support** - Trusted hostnames configuration
- **WebUI & Crypto Setup** - Automated configuration for Access Manager and Session Manager
- **High Availability** - Replication scripts for HA deployments
- **Cloud Optimization** - Compression and encoding for cloud deployments
- **Flexible Configuration** - Command line arguments or JSON configuration files

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/Automation_Showroom.git
cd Automation_Showroom/cloud-init

# Generate basic cloud-init configuration
./wallix_cloud_init_generator.py \
    --output-dir ./output/basic \
    --set-service-user-password

# View generated files
ls -la ./output/basic/
# user-data                 # Main cloud-init file
# network-config           # Network configuration (if --generate-network-config)
# generated_passwords.json # Generated passwords
# config.json             # Configuration used
```

## Installation

### Prerequisites

```bash
# Python 3.6+ (uses only standard library)
python3 --version

# Optional: PyYAML for YAML config files
pip3 install pyyaml
# Or with system packages:
sudo apt-get install python3-yaml  # Debian/Ubuntu
sudo yum install python3-pyyaml    # RHEL/CentOS
```

### File Structure

```ini
cloud-init/
├── wallix_cloud_init_generator.py  # Main script
├── config.example.json            # Example configuration
├── run_examples.sh               # Example runner
├── README.md                    # This documentation
├── templates/                   # Cloud-init templates
│   ├── cloud-init-conf-WALLIX_BASE.tpl
│   ├── cloud-init-conf-WALLIX_ACCOUNTS.tpl
│   └── cloud-init-conf-WALLIX_LB.tpl
├── tools/                       # Helper scripts
│   └── proxmox-wallix-deploy-cloudinit.sh  # Proxmox deployment script
├── scripts/                     # Deployment scripts
│   ├── webadminpass-crypto.py
│   └── install_replication.sh
└── generated/                   # Output directory (auto-created)
```

## Cloud-Init & NoCloud Overview

### What is Cloud-Init?

Cloud-init is the industry standard for cloud instance initialization. It runs during the initial boot of a cloud instance and configures the system according to provided metadata.

**Key Features:**

- User creation and SSH key injection
- Network configuration
- Script execution
- File creation

**Documentation:** [https://cloudinit.readthedocs.io/](https://cloudinit.readthedocs.io/)

### What is NoCloud Datasource?

NoCloud allows cloud-init to run without a cloud provider by reading configuration from local sources (ISO, disk, network).

**Key Files:**

- `user-data`: Main cloud-init configuration (YAML or cloud-config)
- `meta-data`: Instance metadata (instance-id, hostname, etc.)
- `network-config`: Network configuration (optional, Netplan v2 format)

**Documentation:** [https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html)

## Hypervisor Configuration

### VMware vSphere/ESXi

#### Method 1: vApp Properties

```bash
# Generate cloud-init with base64 encoding
./wallix_cloud_init_generator.py \
    --output-dir ./output/vmware \
    --set-service-user-password \
    --to-base64-encode

# In vSphere, configure VM:
# 1. Edit Settings → VM Options → vApp Options
# 2. Enable vApp Options
# 3. Add Properties:
#    - guestinfo.userdata = <base64 encoded user-data>
#    - guestinfo.userdata.encoding = base64
#    - guestinfo.metadata = <base64 encoded meta-data>
#    - guestinfo.metadata.encoding = base64
```

#### Method 2: ISO Image

```bash
# Create ISO with cloud-init files
genisoimage -output cloud-init.iso -volid cidata -joliet -rock user-data meta-data network-config

# Attach ISO to VM as CD-ROM before first boot
```

**VMware Documentation:** [https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-E63B6FAA-8D35-428D-B40C-744769845906.html](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-E63B6FAA-8D35-428D-B40C-744769845906.html)

**Official cloud-init VMware:** [https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html](https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html)

### Proxmox VE

#### Using the Proxmox Deployment Script

We provide a simple deployment script for Proxmox that automates the VM creation and cloud-init configuration:

```bash
# 1. Generate cloud-init configuration with network config
./wallix_cloud_init_generator.py \
    --output-dir ./output/proxmox \
    --set-service-user-password \
    --generate-network-config

# 2. Run the deployment script (must be executed on the Proxmox host)
./tools/proxmox-wallix-deploy-cloudinit.sh ./output/proxmox
```

The deployment script:

- Creates a VM with 8GB RAM and 4 cores
- Configures storage and networking
- Sets up cloud-init with your generated configuration
- Starts the VM automatically

You can edit the script to customize VM settings like ID, name, memory, and storage.

#### Manual Deployment

If you prefer manual deployment, follow these steps:

```bash
# On your local system, generate the cloud-init files
./wallix_cloud_init_generator.py \
    --output-dir ./output/proxmox \
    --set-service-user-password \
    --generate-network-config

# Transfer files to Proxmox host and rename them with VM ID for clarity
scp ./output/proxmox/user-data root@proxmox-host:/var/lib/vz/snippets/user-data-9003
scp ./output/proxmox/network-config root@proxmox-host:/var/lib/vz/snippets/network-config-9003

# On the Proxmox host:
# 1. Download the WALLIX installation image
VMID=9003
VM_NAME="wallix-host-${VMID}"
STORAGE="local"
ISO_PATH="/var/lib/vz/template/iso"
ISO_NAME="wallix-bastion.iso"

# Download the latest WALLIX Bastion image (replace URL with actual download link)
# Upload the ISO to the Proxmox host manually via the web interface

# 2. Create and configure VM
qm create $VMID --name $VM_NAME --memory 8192 --cores 4
qm set $VMID --scsihw virtio-scsi-single

# Create and attach a disk for the system (80GB here)
qm set $VMID --scsi0 $STORAGE:80

# Mount the installation ISO to the CD-ROM drive
qm set $VMID --ide0 "$STORAGE:iso/$ISO_NAME"

# Set up cloud-init drive
qm set $VMID --ide2 $STORAGE:cloudinit

# Configure network
qm set $VMID --net0 virtio,bridge=vmbr0

# Set boot order: first disk, then CD-ROM
# This ensures the VM boots from disk after installation completes
# Proxmox will fall back to CD-ROM if no bootable disk is found
qm set $VMID --boot "order=scsi0;ide0"

# Set machine type to q35 (recommended for newer VMs)
qm set $VMID --machine q35

# Link cloud-init files to the VM
qm set $VMID --cicustom "user=$STORAGE:snippets/user-data-${VMID},network=$STORAGE:snippets/network-config-${VMID}"

# Start the VM - it will boot from the ISO and use your cloud-init settings
qm start $VMID

# 3. Access the VM console via Proxmox web UI to monitor installation


# 4. After installation completes, you can optionally remove the cloud-init configuration:

# 1. Remove the ISO from the VM (prevents cloud-init from re-running)
qm set $VMID --delete ide0

# 2. Change boot order to boot from disk only
qm set $VMID --boot order=scsi0

# 3. Clean up local cloud-init files (optional)
rm -f /var/lib/vz/snippets/user-data-${VMID}
rm -f /var/lib/vz/snippets/network-config-${VMID}

# Note: Keep the cloud-init drive (ide2) if you want to reconfigure the VM later
# To completely remove cloud-init drive:
qm set $VMID --delete ide2

```

**Proxmox Documentation:** [https://pve.proxmox.com/wiki/Cloud-Init_Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)

### KVM/QEMU

#### Configuration avec ISO Cloud-Init

```bash
# Generate cloud-init files
./wallix_cloud_init_generator.py \
    --output-dir ./output/kvm \
    --set-service-user-password \
    --generate-network-config

# Create meta-data file
cat > ./output/kvm/meta-data <<EOF
instance-id: wallix-001
local-hostname: wallix-bastion
EOF

# Create cloud-init ISO
cd ./output/kvm
genisoimage -output cloud-init.iso -volid cidata -joliet -rock \
    user-data meta-data network-config

# Launch VM with cloud-init ISO
virt-install \
  --name wallix-bastion \
  --memory 8192 \
  --vcpus 4 \
  --disk /var/lib/libvirt/images/wallix.qcow2 \
  --disk ./cloud-init.iso,device=cdrom \
  --network bridge=virbr0 \
  --os-variant ubuntu20.04 \
  --import
```

**KVM Documentation:** [https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#iso-example](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#iso-example)

### Hyper-V

#### Configuration avec ISO Cloud-Init

```powershell
# Generate cloud-init files
./wallix_cloud_init_generator.py `
    --output-dir ./output/hyperv `
    --set-service-user-password

# Create ISO on Windows (using PowerShell)
# Install Windows ADK for oscdimg tool
# https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

# Create ISO
oscdimg -n -m .\output\hyperv cloud-init.iso

# Create and configure VM
New-VM -Name "WALLIX-Bastion" -MemoryStartupBytes 8GB -Generation 2
Add-VMHardDiskDrive -VMName "WALLIX-Bastion" -Path "C:\VMs\wallix.vhdx"
Add-VMDvdDrive -VMName "WALLIX-Bastion" -Path ".\cloud-init.iso"
```

**Hyper-V Documentation:** [https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/)

### VirtualBox

#### Configuration avec ISO Cloud-Init

```bash
# Generate cloud-init files
./wallix_cloud_init_generator.py \
    --output-dir ./output/virtualbox \
    --set-service-user-password

# Create meta-data
echo -e "instance-id: wallix-001\nlocal-hostname: wallix-bastion" > ./output/virtualbox/meta-data

# Create ISO (Linux/Mac)
genisoimage -output cloud-init.iso -volid cidata -joliet -rock \
    ./output/virtualbox/user-data ./output/virtualbox/meta-data

# Create VM and attach ISO
VBoxManage createvm --name "WALLIX-Bastion" --ostype Ubuntu_64 --register
VBoxManage modifyvm "WALLIX-Bastion" --memory 8192 --cpus 4
VBoxManage storagectl "WALLIX-Bastion" --name "IDE Controller" --add ide
VBoxManage storageattach "WALLIX-Bastion" --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive --medium ./cloud-init.iso
```

**VirtualBox Documentation:** [https://www.virtualbox.org/manual/ch08.html](https://www.virtualbox.org/manual/ch08.html)

## Usage Examples

### Basic Configuration

```bash
# Minimal configuration with service passwords
./wallix_cloud_init_generator.py \
    --output-dir ./output/basic \
    --set-service-user-password
```

### Access Manager with Load Balancer

```bash
./wallix_cloud_init_generator.py \
    --output-dir ./output/access-manager \
    --product-type access-manager \
    --set-service-user-password \
    --use-of-lb \
    --http-host-trusted-hostnames "lb.example.com,backup-lb.example.com" \
    --set-webui-password-and-crypto \
    --generate-network-config \
    --network-interfaces ens192:dhcp4 ens224:dhcp4 ens256:dhcp4 ens288:dhcp4
```

### Session Manager with Replication

```bash
./wallix_cloud_init_generator.py \
    --output-dir ./output/session-manager \
    --product-type session-manager \
    --set-service-user-password \
    --set-webui-password-and-crypto \
    --install-replication \
    --hostname sm-primary \
    --fqdn sm-primary.domain.local
```

### Static Network Configuration

```bash
./wallix_cloud_init_generator.py \
    --output-dir ./output/static-network \
    --set-service-user-password \
    --generate-network-config \
    --network-interfaces eth0:static \
    --static-ip-config "eth0:192.168.1.100/24:192.168.1.1:8.8.8.8,8.8.4.4"
```

### Cloud-Optimized (Compressed & Encoded)

```bash
./wallix_cloud_init_generator.py \
    --output-dir ./output/cloud \
    --set-service-user-password \
    --to-gzip \
    --to-base64-encode
```

### JSON Configuration File

```json
{
  "product_type": "access-manager",
  "hostname": "wam-prod-01",
  "fqdn": "wam-prod-01.company.local",
  "set_service_user_password": true,
  "use_of_lb": true,
  "http_host_trusted_hostnames": "wallix-lb.company.local",
  "set_webui_password_and_crypto": true,
  "install_replication": false,
  "generate_network_config": true,
  "network_interfaces": ["eth0:static"],
  "static_ip_config": ["eth0:10.0.1.100/24:10.0.1.1:10.0.1.10,10.0.1.11"],
  "to_gzip": false,
  "to_base64_encode": true
}
```

```bash
# Use JSON configuration
./wallix_cloud_init_generator.py \
    --output-dir ./output/from-json \
    --config-file config.json
```

## Network Configuration

### DHCP Configuration

```bash
./wallix_cloud_init_generator.py \
    --generate-network-config \
    --network-interfaces eth0:dhcp4
```

### Multiple Interfaces

```bash
./wallix_cloud_init_generator.py \
    --generate-network-config \
    --network-interfaces eth0:dhcp4 eth1:static \
    --static-ip-config "eth1:192.168.100.10/24:192.168.100.1:8.8.8.8"
```

### Network Bonding

```bash
./wallix_cloud_init_generator.py \
    --generate-network-config \
    --network-interfaces bond0:static \
    --network-bonds "bond0:eth0,eth1:active-backup" \
    --static-ip-config "bond0:10.0.1.100/24:10.0.1.1:10.0.1.1"
```

### VLAN Configuration

```bash
./wallix_cloud_init_generator.py \
    --generate-network-config \
    --network-interfaces eth0:manual vlan100:static \
    --network-vlans "vlan100:eth0:100" \
    --static-ip-config "vlan100:192.168.100.10/24:192.168.100.1:8.8.8.8"
```

## Generated Files

### user-data

Main cloud-init configuration file containing:

- User account setup
- Package installation
- Service configuration
- Scripts to run

### network-config

Network configuration in Netplan v2 format (when `--generate-network-config` is used)

### meta-data

Instance metadata (create manually):

```yaml
instance-id: wallix-instance-001
local-hostname: wallix-bastion
```

### generated_passwords.json

Securely generated passwords:

```json
{
  "password_wabadmin": "SecurePass123+",
  "password_wabsuper": "AnotherPass456=",
  "password_wabupgrade": "UpgradePass789-",
  "webui_password": "WebUIPass012_",
  "cryptokey_password": "CryptoKey345+"
}
```

## Integration

### Terraform Integration

```hcl
# Load generated files
data "local_file" "user_data" {
  filename = "${path.module}/cloud-init/generated/basic/user-data"
}

data "local_file" "network_config" {
  filename = "${path.module}/cloud-init/generated/basic/network-config"
}

data "local_file" "passwords" {
  filename = "${path.module}/cloud-init/generated/basic/generated_passwords.json"
}

locals {
  passwords = jsondecode(data.local_file.passwords.content)
}

# VMware vSphere
resource "vsphere_virtual_machine" "wallix" {
  name             = "wallix-bastion"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  extra_config = {
    "guestinfo.userdata"          = base64encode(data.local_file.user_data.content)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(file("${path.module}/meta-data"))
    "guestinfo.metadata.encoding" = "base64"
  }
}

# AWS EC2
resource "aws_instance" "wallix" {
  ami           = var.wallix_ami
  instance_type = "t3.xlarge"
  user_data     = data.local_file.user_data.content

  tags = {
    Name = "WALLIX-Bastion"
  }
}

# Azure VM
resource "azurerm_linux_virtual_machine" "wallix" {
  name                = "wallix-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D4s_v3"

  custom_data = base64encode(data.local_file.user_data.content)
}

# Output passwords
output "admin_password" {
  value     = local.passwords.password_wabadmin
  sensitive = true
}
```

### Ansible Integration

```yaml
---
- name: Deploy WALLIX with Cloud-Init
  hosts: hypervisors
  tasks:
    - name: Generate cloud-init configuration
      command: |
        ./wallix_cloud_init_generator.py \
          --output-dir /tmp/wallix-cloudinit \
          --set-service-user-password \
          --generate-network-config
      delegate_to: localhost

    - name: Create cloud-init ISO
      command: |
        genisoimage -output /tmp/cloud-init.iso -volid cidata \
          -joliet -rock /tmp/wallix-cloudinit/user-data \
          /tmp/wallix-cloudinit/meta-data \
          /tmp/wallix-cloudinit/network-config
      delegate_to: localhost

    - name: Copy ISO to hypervisor
      copy:
        src: /tmp/cloud-init.iso
        dest: /var/lib/libvirt/images/cloud-init.iso

    - name: Deploy VM
      virt:
        name: wallix-bastion
        command: define
        xml: "{{ lookup('template', 'vm-template.xml.j2') }}"
```

### Packer Integration

```hcl
source "vmware-iso" "wallix" {
  vm_name          = "wallix-bastion"
  guest_os_type    = "ubuntu64Guest"
  iso_url          = var.wallix_iso_url
  iso_checksum     = var.wallix_iso_checksum
  
  cd_files = [
    "${path.root}/generated/user-data",
    "${path.root}/generated/meta-data",
    "${path.root}/generated/network-config"
  ]
  cd_label = "cidata"
}

build {
  sources = ["source.vmware-iso.wallix"]
  
  provisioner "shell-local" {
    inline = [
      "./wallix_cloud_init_generator.py --output-dir generated --set-service-user-password"
    ]
  }
}
```

## Security

### Password Generation

- **Algorithm**: Python's `secrets` module (cryptographically secure)
- **Length**: Minimum 16 characters
- **Complexity**: Uppercase, lowercase, digits, special characters
- **Special Characters**: Limited to `-_=+` to avoid shell escaping issues

### Best Practices

1. **Never commit passwords**: Add `generated_passwords.json` to `.gitignore`
2. **Use secrets management**: Store passwords in HashiCorp Vault, AWS Secrets Manager, etc.
3. **Rotate passwords**: Change default passwords after first login
4. **Secure transmission**: Use HTTPS/SSH for file transfers
5. **Limit access**: Restrict access to cloud-init files

### Example with HashiCorp Vault or OpenBao

```bash
# Store passwords in Vault
vault kv put secret/wallix/passwords @generated_passwords.json

# Retrieve in Terraform
data "vault_generic_secret" "wallix_passwords" {
  path = "secret/wallix/passwords"
}
```

## Troubleshooting

### Common Issues

#### Cloud-init not running

```bash
# Check cloud-init status
cloud-init status --long

# Check logs
sudo journalctl -u cloud-init
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Manually run cloud-init
sudo cloud-init clean --logs
sudo cloud-init init --local
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final
```

#### Network configuration not applied

```bash
# Verify datasource
cloud-init query datasource

# Check network-config syntax
cloud-init devel schema --config-file network-config

# Debug network configuration
sudo netplan --debug generate
sudo netplan --debug apply
```

#### Passwords not working

```bash
# Verify password generation
cat generated_passwords.json | jq

# Check user-data for password fields
grep -A 5 "wabadmin_password" user-data

# Test password manually
echo "password" | sudo -S -u wabadmin id
```

#### ISO not detected

```bash
# Verify ISO label
blkid | grep cidata

# Mount and check contents
sudo mkdir /mnt/cidata
sudo mount /dev/sr0 /mnt/cidata
ls -la /mnt/cidata/

# Check cloud-init datasource
cloud-init query --list-keys
```

### Debug Mode

```bash
# Enable debug in user-data
#cloud-config
debug: true
```

### Validation Tools

```bash
# Validate cloud-config syntax
cloud-init devel schema --config-file user-data

# Validate network-config
cloud-init devel schema --config-file network-config --schema-type network-config

# Test locally with LXD
lxc launch ubuntu:20.04 test-wallix --config=user.user-data="$(cat user-data)"
```

## Additional Resources

### Official Documentation

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [NoCloud Datasource](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html)
- [Network Configuration v2](https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html)

### Hypervisor Specific

- [VMware and Cloud-Init](https://williamlam.com/2020/06/using-cloud-init-with-vmware-vsphere-for-linux-guest-os-customization.html)
- [Proxmox Cloud-Init](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [KVM and Cloud-Init](https://stafwag.github.io/blog/blog/2019/03/03/howto-use-cloud-init-local/)
- [Hyper-V Linux Integration](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-ubuntu-virtual-machines-on-hyper-v)

### Tools and Utilities

- [cloud-localds](https://manpages.ubuntu.com/manpages/focal/man1/cloud-localds.1.html) - Create NoCloud ISO
- [cloud-init-validator](https://cloud-init.io/) - Online validation tool
- [Packer](https://www.packer.io/) - Automated image building
- [Terraform](https://www.terraform.io/) - Infrastructure as Code

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes with `./run_examples.sh`
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request
