# Deploy WALLIX on Azure with Terraform

| Example | What it deploys |
| --- | --- |
| [01-Basic/bastion-vhd](01-Basic/bastion-vhd/) | One WALLIX Bastion VM built from a VHD, in an existing VNet |
| [01-Basic/access-manager-vhd](01-Basic/access-manager-vhd/) | One WALLIX Access Manager VM built from a VHD, in an existing VNet |

## Authentication

The azurerm provider uses the Azure CLI session by default. Log in and select the subscription before running Terraform:

```bash
az login
az account set --subscription <subscription-id>
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

Since azurerm 4.0 the subscription ID must be set explicitly, either with `ARM_SUBSCRIPTION_ID` or with the `subscription_id` variable of each example. Service principals, managed identities and OIDC are also supported; see the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).

## How the VHD examples work

WALLIX Bastion and Access Manager are delivered on Azure as VHD files. The examples expect the VHD in a container named `vhds` of an existing storage account, named `bastion-<version>-azure.vhd` or `access-manager-<version>-azure.vhd`. Terraform builds a managed image from that blob, then creates a VM from the image with a managed OS disk.

Earlier versions of these examples booted the VM directly on a copy of the VHD (unmanaged OS disk). Azure retired unmanaged disks on March 31, 2026, so that approach no longer works.

A cloud-init configuration sets the passwords of the WALLIX service accounts at first boot, so the appliance does not stop on its initial configuration screens.

## Inputs

Each example takes its inputs from Terraform variables. Copy `terraform.auto.tfvars.example` to `terraform.auto.tfvars` in the example folder and fill in the placeholders; Terraform loads it automatically. `*.tfvars` files are ignored by Git in this repository because they hold passwords.
