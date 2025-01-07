<!-- markdownlint-disable MD033 -->
# Group Mapping

This is an example of provisionning of User Groups and Authentication Domain Group Mapping form a json extract.

## How to use

### With EntraID

Generate a data.json file

```bash
az ad group list --output json > input_data.json
```

Adapt the variables.

```bash
cp config.tfvars.example config.tfvars
```

run it with:

```bash
terraform init
terraform apply -var-file=config.tvfars
```

After testing you can remove change with:

```bash
terraform destroy -var-file=config.tvfars
```

### Adapt locals

This example take for base EntraID, if you want to use it with another set of data please adapt the json key to use in the locals.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=v1.10.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_wallix-bastion"></a> [wallix-bastion](#requirement\_wallix-bastion) | >=0.14.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_wallix-bastion"></a> [wallix-bastion](#provider\_wallix-bastion) | 0.14.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [wallix-bastion_authdomain_mapping.test](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_usergroup.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authdomain_id"></a> [authdomain\_id](#input\_authdomain\_id) | Id of the authdomain were mapping will be created! | `string` | n/a | yes |
| <a name="input_bastion_info_api_version"></a> [bastion\_info\_api\_version](#input\_bastion\_info\_api\_version) | This is the version of api used to call api. | `string` | `"v3.12"` | no |
| <a name="input_bastion_info_ip"></a> [bastion\_info\_ip](#input\_bastion\_info\_ip) | IP of the bastion | `string` | n/a | yes |
| <a name="input_bastion_info_port"></a> [bastion\_info\_port](#input\_bastion\_info\_port) | This is the tcp port for https connection on bastion API. | `string` | `"443"` | no |
| <a name="input_bastion_info_token"></a> [bastion\_info\_token](#input\_bastion\_info\_token) | This is the token to authenticate on bastion API. | `string` | n/a | yes |
| <a name="input_bastion_info_user"></a> [bastion\_info\_user](#input\_bastion\_info\_user) | This is the username used to authenticate on bastion API. | `string` | `"admin"` | no |
| <a name="input_profil_mapping"></a> [profil\_mapping](#input\_profil\_mapping) | Map value of the user\_group name and the profil to set. Profil must exist on bastion. By default user will be use | `map(string)` | <pre>{<br/>  "PAM_Approver_EntraID_Group": "approver",<br/>  "PAM_Auditor_EntraIDGroup": "product_administrator",<br/>  "PAM_Operation_Administrator": "operation_administrator",<br/>  "PAM_System_Administrator": "system_administrator",<br/>  "PAM_User": "user"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->