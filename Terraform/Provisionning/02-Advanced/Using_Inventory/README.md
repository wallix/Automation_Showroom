# Using an inventory

These use cases describe users, servers and access rules in a YAML file (`data_input/inventory.yaml`) and let Terraform build the Bastion objects from it. The Terraform code stays the same from one customer to another; only the inventory changes. Adding a user or a server is a few lines of YAML followed by `terraform apply`.

The three use cases differ by the unit of access, which drives how many authorizations the Bastion ends up with:

| Use case | One authorization per | Accounts on the targets | Fits when |
| -------- | --------------------- | ----------------------- | --------- |
| [UseCase1](UseCase1%20-%20OneAuthorizationPerUser/) | user | one personal account per user, in a global domain | each person has a named account on the servers |
| [UseCase2](UseCase2%20-%20OneAuthorizationPerDepartment/) | department (user group) | one shared account per server (`root`, `administrator`), in a local domain | a team shares the privileged accounts of its servers |
| [UseCase3](UseCase3%20-%20OneAuthorizationPerTargetService/) | account of a server | several accounts per server, in a local domain | access is granted account by account (`root` for the admins, `helpdesk` for the helpdesk) |

## How the inventory is read

`main.tf` decodes the file once, and the resources iterate over its maps with `for_each`:

```hcl
locals {
  inventory = yamldecode(file("${path.module}/data_input/inventory.yaml"))
}

resource "wallix-bastion_device" "vms" {
  for_each    = local.inventory.vms_inventory
  device_name = each.value.name
  host        = each.value.ip
}
```

The keys of the YAML maps become the keys of the Terraform resources (`wallix-bastion_device.vms["windows_common01"]`). Keep them stable: renaming a key destroys and recreates its objects on the Bastion, while changing a value (an IP, a display name) updates them in place. The other lists of the inventory refer to these keys.

## Run a use case

Each folder runs on its own. The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cd "UseCase1 - OneAuthorizationPerUser"
cp config.tfvars.example config.tfvars           # set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform plan -var-file=config.tfvars           # review what the inventory produces
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

The servers of the inventories are placeholders (`192.168.1.x`) and the account passwords are random: the Bastion objects are created, but sessions only open once the inventory points at real servers and the vault holds their real credentials.
