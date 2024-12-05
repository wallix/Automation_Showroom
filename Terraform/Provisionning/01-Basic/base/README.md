<!-- markdownlint-disable MD033 -->
# Base

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
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_wallix-bastion"></a> [wallix-bastion](#requirement\_wallix-bastion) | >=0.12.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.2 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |
| <a name="provider_wallix-bastion"></a> [wallix-bastion](#provider\_wallix-bastion) | 0.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_pet.group](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/pet) | resource |
| [random_pet.user](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/pet) | resource |
| [random_string.demo](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/string) | resource |
| [tls_private_key.rsa-4096](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [wallix-bastion_authorization.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_domain.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_targetgroup.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_user.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_version.version](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_info_api_version"></a> [bastion\_info\_api\_version](#input\_bastion\_info\_api\_version) | This is the version of api used to call api. | `string` | `"v3.12"` | no |
| <a name="input_bastion_info_ip"></a> [bastion\_info\_ip](#input\_bastion\_info\_ip) | IP of the bastion | `string` | n/a | yes |
| <a name="input_bastion_info_port"></a> [bastion\_info\_port](#input\_bastion\_info\_port) | This is the tcp port for https connection on bastion API. | `string` | `"443"` | no |
| <a name="input_bastion_info_token"></a> [bastion\_info\_token](#input\_bastion\_info\_token) | This is the token to authenticate on bastion API. | `string` | n/a | yes |
| <a name="input_bastion_info_user"></a> [bastion\_info\_user](#input\_bastion\_info\_user) | This is the username used to authenticate on bastion API. | `string` | `"admin"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_group"></a> [group](#output\_group) | Generated Group Name |
| <a name="output_password"></a> [password](#output\_password) | Randomly generated password for the user |
| <a name="output_username"></a> [username](#output\_username) | Generated Username |
| <a name="output_version_info"></a> [version\_info](#output\_version\_info) | Session Manager version info |
<!-- END_TF_DOCS -->