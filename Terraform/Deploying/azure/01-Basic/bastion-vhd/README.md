<!-- markdownlint-disable MD033 -->
# Deploy a WALLIX Bastion on Azure from a VHD

This example creates one WALLIX Bastion VM in an existing VNet and subnet. It builds a managed image from the Bastion VHD stored in your storage account, creates the VM from it, and sets the `wabadmin`, `wabsuper` and `wabupgrade` passwords with cloud-init. By default the VM only has a private IP; a public IP restricted to your addresses is optional. A daily auto-shutdown at 21:00 (Central Europe time) keeps lab costs down.

It is meant for labs and evaluations, not for production.

## Prerequisites

* Terraform 1.9 or later, and an Azure session (see [../../README.md](../../README.md)).
* An existing resource group containing the VNet, the subnet and the storage account. The storage account must be in the same region as the resource group.
* The Bastion VHD uploaded as a page blob to `vhds/bastion-<bastion_version>-azure.vhd` in that storage account, for example:

  ```bash
  az storage blob upload --account-name <storage-account> --container-name vhds \
    --type page --name bastion-<version>-azure.vhd --file bastion-<version>-azure.vhd --auth-mode login
  ```

* An SSH public key.

## Deploy

```bash
cp terraform.auto.tfvars.example terraform.auto.tfvars
vi terraform.auto.tfvars          # replace every <...> placeholder

terraform init
terraform apply
```

### Inputs that matter

| Name | Why it matters |
| --- | --- |
| `bastion_version` | Selects the VHD blob; it must match the file name exactly. |
| `allowed_ips` | Empty: private VM only. Non-empty: a static public IP and an NSG opening 22, 80, 443, 2242 and 3389 to these CIDRs only. |
| `wabadmin_password`, `wabsuper_password`, `wabupgrade_password` | Service account passwords. `wabadmin` is also the Azure admin account, so its password must meet Azure complexity rules. |
| `ssh_key` | Public key authorized for `wabadmin`. |
| `subscription_id` | Optional when `ARM_SUBSCRIPTION_ID` is set. |

## Connect

Use `terraform output public_ip` (or `private_ip` from inside the VNet):

* Web UI: `https://<ip>/` (self-signed certificate).
* SSH administration: `ssh -p 2242 wabadmin@<ip>`.

By default the web UI only accepts requests addressed to the private IP or the machine name. If you go through the public IP, map the machine name (`vm_name`) to that IP in your hosts file for the initial configuration.

## Destroy

```bash
terraform destroy
```

The managed image, the OS disk, the NIC and the optional public IP and NSG are deleted. The VHD blob in your storage account is left untouched.

## Security notes

* With `allowed_ips` set, the VM has a public IP. Use your own `/32`; `0.0.0.0/0` exposes the web UI, SSH administration and the session proxies to the Internet.
* The passwords are stored in cleartext in `terraform.auto.tfvars` and in the Terraform state. Keep both out of version control and change the passwords after the first login.
* Password authentication is enabled for `wabadmin` alongside the SSH key.

## Reference

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | ~> 1.9 |
| azurerm | ~> 5.0 |
| cloudinit | ~> 2.3 |

### Resources

| Name | Type |
| ---- | ---- |
| [azurerm_dev_test_global_vm_shutdown_schedule.auto-shutdown-bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_test_global_vm_shutdown_schedule) | resource |
| [azurerm_image.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/image) | resource |
| [azurerm_linux_virtual_machine.vm-bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.vhds](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.lab-subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [cloudinit_config.cloudinit_bastion](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| resource\_group\_name | Name of the existing Resource Group in which the objects are created. The storage account and the VNet must be in it too. | `string` | n/a | yes |
| ssh\_key | SSH public key (OpenSSH format) authorized for wabadmin, e.g. file("~/.ssh/id\_ed25519.pub") content. | `string` | n/a | yes |
| storage\_account\_name | Name of the existing Storage Account holding the WALLIX VHD in its vhds container. Must be in the same region as the Resource Group. | `string` | n/a | yes |
| subnet\_name | Name of the existing Subnet in which the VM is attached. | `string` | n/a | yes |
| virtual\_network\_name | Name of the existing Virtual Network. | `string` | n/a | yes |
| vm\_name | Name of the virtual machine, also used as prefix for the related resources. | `string` | n/a | yes |
| wabadmin\_password | Password of the wabadmin account (also the Azure admin account). | `string` | n/a | yes |
| wabsuper\_password | Password of the wabsuper account. | `string` | n/a | yes |
| wabupgrade\_password | Password of the wabupgrade account. | `string` | n/a | yes |
| allowed\_ips | Public CIDR blocks allowed to reach the VM. Empty (default): no public IP and no NSG are created. Otherwise a static public IP and an NSG opening 22, 80, 443, 2242 and 3389 to these CIDRs. | `list(string)` | `[]` | no |
| bastion\_version | Bastion version as found in the VHD name: vhds/bastion-<bastion\_version>-azure.vhd. | `string` | `"10.0.2.9"` | no |
| os\_disk\_type | Storage type of the managed image and OS disk (Standard\_LRS, StandardSSD\_LRS, Premium\_LRS). | `string` | `"StandardSSD_LRS"` | no |
| subscription\_id | Azure subscription ID. If null, ARM\_SUBSCRIPTION\_ID must be set. | `string` | `null` | no |
| vm\_size | VM size. Run az vm list-sizes to list available options. | `string` | `"Standard_B2ms"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| private\_ip | Private IP of the VM. |
| public\_ip | Public IP of the VM, null when allowed\_ips is empty. |
| vm\_id | ID of the VM. |
<!-- END_TF_DOCS -->
