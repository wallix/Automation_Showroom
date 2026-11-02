# Group Mapping (Entra ID)

Creates one Bastion user group per Entra ID group and maps them, so that a user who logs in through Entra ID gets the Bastion groups (and profile) of their Entra ID groups. The group list comes from a JSON export of the Azure CLI, which keeps the example independent of any Graph API credential in Terraform.

## Prerequisites

- An Entra ID authentication domain already configured on the Bastion (resource `wallix-bastion_authdomain_azuread`, or the web UI). This example looks it up by name and doesn't change it.
- The profiles named in `profile_mapping` exist on the Bastion (`approver`, `auditor`, `user`... are built in).
- The [connection settings](../../README.md#before-you-start) shared by all the examples.

## Run it

Export the groups to map. Filter them: `az ad group list` without a filter returns every group of the tenant, and the example would create one Bastion user group for each.

```bash
az ad group list --filter "startswith(displayName,'PAM_')" \
  --query "[].{id:id, mailNickname:mailNickname, description:description}" --output json > input_data.json
```

`input_data.json.example` shows the expected format; copy it to `input_data.json` to try the example without Azure.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and authdomain_name
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## How it works

| Entra ID (input_data.json) | Bastion |
| -------------------------- | ------- |
| `mailNickname` | user group name, and key of `profile_mapping` |
| `description` | user group description |
| `id` (group object ID) | `external_group` of the mapping |

Re-export the file and apply again to follow the changes in Entra ID: a group removed from the file removes its Bastion user group and mapping.

To use another source (LDAP, another IdP export), keep the same structure and change the keys read in the `locals` block of `main.tf`. For an OIDC identity provider, see [OIDC_Authentication](../OIDC_Authentication/).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_authdomain_mapping.entra](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_usergroup.entra](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_authdomain_azuread.entra](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/authdomain_azuread) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| authdomain\_name | Domain name of the Entra ID authentication domain that already exists on the Bastion. | `string` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| input\_file | JSON export of the Entra ID groups (az ad group list --output json). | `string` | `"input_data.json"` | no |
| profile\_mapping | Bastion profile per group (mailNickname). The profile must exist on the Bastion; unlisted groups get "user". | `map(string)` | ```{ "PAM_Approver": "approver", "PAM_Auditor": "auditor", "PAM_Operation_Administrator": "operation_administrator", "PAM_System_Administrator": "system_administrator", "PAM_User": "user" }``` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| mappings | Bastion user group => Entra ID group object ID. |
<!-- END_TF_DOCS -->
