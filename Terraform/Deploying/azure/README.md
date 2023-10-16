# Azure deployments with Terraform

Deployments of the various resources, vms, networks and automation alike can be done by using terraform and the azurerm provider.

## Azure Authentication

Terraform needs an authentication to Azure to create, manage and delete the resources. Various methods of authentication exist, as described in the [documentation of the azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).

When authenticated through the CLI, Terraform will use those credentials to authenticate against Azure as long as they are valid and present on the system, meaning that there is no need to refresh them between two deployments if those are done back-to-back.

It is possible to connect via the CLI in a non-interactive way that would be compatible with using it in scripts, by using a dedicated account created directly on azure or with a service principal linked to an application.

The command to login to Azure using the CLI with an user account is `az login`. If the account that is used for the login has access to several subscriptions, the command `az account set --subscription <subscription>` should be used to ensure that the right subscription is selected.\
Terraform also has the possibility to authenticate using info passed in the azurerm provider's configuration.

## Necessary information

Each terraform template requires specific information to identify both the resources to be created and the already existing resources to be used.
All the required information is given using terraform variables.

While most of it is specific to the type of resource to be deployed, the name of the resource group on which to deploy them is mandatory for all of them.

## Windows and Linux vms

A generic vm, be it windows or linux, can be deployed using the images that are publicly available on Azure as base. This implies that the appropriate information to retrieve the right image must be provided. This also means that the osdisk created for this vm using the base image will be a full-blown managed disk.\
They are also deployed using the dedicated terraform resources `azurerm_linux_virtual_machine` and `azurerm_windows_virtual_machine` rather than the generic `azurerm_virtual_machine`.

For Windows vms, as ssh is **not** enabled by default on the system, it is mandatory to add the openssh vm extension so that it configures the vm to use ssh.

Adding an ssh public key to allow for ssh connection using a private key must be done separately and can be done using a custom script extension to run the appropriate command.

## Bastion and Access Manager

Bastion and Access Manager instances are created by cloning the vhd corresponding to the chosen version to create the osdisk vhd. Those disks are not managed. They have to be stored in an existing storage account located in the same region as the resource group. Due to limitations on Azure's side, the osdisk vhd and the original vhd have to be stored within the same storage account.

Expected vhd naming convention is bastion-${var.bastion_version}-azure.vhd or access-manager-${var.am_version}-azure.vhd and are also expected to be placed under a "vhds" repository on the storage account.

Starting a Bastion or an Access Manager instance by only using the vhd as base delivers the vm as ready to be configured through the blue screens. By using cloudinit to provide additional configuration, it is possible to bypass the bluescreens and have the system configure itself to deliver a ready-to-use instance.

NOTE: The default terraform example have the public IP generation commented out so you will need an access from an other virtual machine to do the Webui configuration. Also the auto turn off is applied for reducing cost. Comment the blocks of code if needed.

By default the bastion allow access to the internal IP or the machine name so you may need to change your host file for first configuration.

It is a known issue that the dynamic public ip address cannot be populated in one single apply.
To workaround this, you will have to run terraform refresh and get that public ip address in the vm.
