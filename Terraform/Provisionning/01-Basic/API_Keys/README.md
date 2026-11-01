# API Keys

An API key lets a script or a tool call the REST API without a user password. A v2 key (`wallix-bastion_apikey_v2`, API v3.12) is bound to a profile that limits what it can do, and can be restricted to a few source addresses: give each tool its own key, with the smallest profile that covers its job.

## What it creates

```text
API key "<prefix>-reporting"
  ├── profile: auditor (built-in, read with the wallix-bastion_profile data source)
  └── usable from: 192.0.2.50 only
```

The key name starts with a random prefix (`apikey-<adjective>-<animal>`), so the example can run several times on a shared Bastion.

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and the addresses of the tool
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output apikey_rights                   # what the profile of the key allows
```

A tool authenticates with the `X-Auth-Key` header (the key) and the `X-Auth-User` header (a Bastion user name), as described in the REST API documentation. Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **Terraform doesn't give you the value of the key.** The provider reads the `apikey` attribute back as `********` (checked on a Bastion 12.4.3). The provider documentation says the value is only available in the web UI, when the key is created there: for a key a tool will use, create it in the web UI and bring it under Terraform with `terraform import wallix-bastion_apikey_v2.reporting <apikey_name>`.
- **Use a built-in profile.** A profile created with `wallix-bastion_profile`, even with `view` rights only, is refused: `409 The API key must be associated to a read-only profile` (Bastion 12.4.3). `auditor` (session audit, read-only) is accepted.
- **Changing `profile` or `ip_limitation` replaces the key**, as the API can't change them: the tool then needs the new key.
- **Don't use `wallix-bastion_apikey` (v1).** The REST API documentation marks it deprecated and gives its keys the `product_administrator` profile, that is every right on the Bastion.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| random | ~> 3.9 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wallix-bastion_apikey_v2.reporting](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/apikey_v2) | resource |
| [wallix-bastion_profile.key](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/profile) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| allowed\_source\_ips | IP addresses the automation tool calls the REST API from. Empty list: any address. | `list(string)` | ```[ "192.0.2.50" ]``` | no |
| apikey\_profile | Built-in profile that limits the rights of the key, e.g. auditor (session audit, read-only). | `string` | `"auditor"` | no |
| bastion\_info\_api\_version | Version of the REST API. API keys bound to a profile require v3.12. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| apikey\_name | Name of the API key, as listed in the Bastion. |
| apikey\_rights | Rights the profile gives to the key (view or modify, per feature). |
<!-- END_TF_DOCS -->
