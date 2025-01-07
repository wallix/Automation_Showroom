<!-- markdownlint-disable-file MD033 -->
# UseCase3 - OneAuthorizationPerTargetService

## Base

This is a mix and match example. A bastion should already be on place and an API Key set.

Please copy config.tvfars.example to config.tvfars and change it to you needs.

run it with:

```bash
terraform init
terraform apply -var-file=config.tvfars

```

After testing you can remove change with:

```bash
terraform destroy -var-file=config.tvfars
```

## Advanced

Instructions for using inventory variables in Terraform

1. Define Inventory Variables
All inventory variables are set in the file: data_input/inventory.yml

2. Ensure Proper Formatting
The inventory.yml file must follow a valid YAML structure.

3. Declare the Inventory File in the Root Module
In the root module’s main.tf, the inventory file is declared as a local variable using yamldecode.

4. Access the Variables
Use local.<key> to call the variables in your Terraform files.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.5.1 |
| <a name="requirement_wallix-bastion"></a> [wallix-bastion](#requirement\_wallix-bastion) | >=0.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |
| <a name="provider_wallix-bastion"></a> [wallix-bastion](#provider\_wallix-bastion) | 0.14.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_password.primary_accounts](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.secondary_accounts](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [wallix-bastion_authorization.Demo_UseCase3_Autorizations](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.Demo_UseCase3_Devices](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_localdomain.Demo_UseCase3_Localdomain](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain) | resource |
| [wallix-bastion_device_localdomain_account.Demo_UseCase3_Localdomain_Accounts](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain_account) | resource |
| [wallix-bastion_device_localdomain_account_credential.Demo_UseCase3_LocalDomain_Accounts_Credentials_Password](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain_account_credential) | resource |
| [wallix-bastion_device_localdomain_account_credential.Demo_UseCase3_Localdomain_Accounts_Credentials_SSH](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain_account_credential) | resource |
| [wallix-bastion_device_service.Demo_UseCase3_Service_RDP](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_device_service.Demo_UseCase3_Service_SSH](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_targetgroup.Demo_UseCase3_Target_Groups](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_user.Demo_UseCase3_Users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.Demo_UseCase3_User_Groups](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_version.version](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info_api_version"></a> [bastion\_info\_api\_version](#input\_bastion\_info\_api\_version) | This is the version of api used to call api. | `string` | `"v3.8"` | no |
| <a name="input_bastion_info_ip"></a> [bastion\_info\_ip](#input\_bastion\_info\_ip) | IP of the bastion | `string` | n/a | yes |
| <a name="input_bastion_info_password"></a> [bastion\_info\_password](#input\_bastion\_info\_password) | This is the password used to authenticate on bastion API. | `string` | `"admin"` | no |
| <a name="input_bastion_info_port"></a> [bastion\_info\_port](#input\_bastion\_info\_port) | This is the tcp port for https connection on bastion API. | `string` | `"443"` | no |
| <a name="input_bastion_info_token"></a> [bastion\_info\_token](#input\_bastion\_info\_token) | This is the token to authenticate on bastion API. | `string` | n/a | yes |
| <a name="input_bastion_info_user"></a> [bastion\_info\_user](#input\_bastion\_info\_user) | This is the username used to authenticate on bastion API. | `string` | `"admin"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->