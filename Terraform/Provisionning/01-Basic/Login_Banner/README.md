# Login Banner

Every Bastion has a login banner and a message of the day, in five languages, usually holding a legal warning and operational information. This example sets their English text.

## What it creates

Nothing new: the messages always exist on the Bastion, and Terraform sets their text.

```text
connection message "login_en" (Bastion-wide) ── "WARNING: Access restricted to authorized users..."
connection message "motd_en"  (Bastion-wide) ── "Maintenance window every Sunday..."
```

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and the texts
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

## Things to know

- **The messages are Bastion-wide, and destroy doesn't restore them**: `terraform destroy` leaves the last text applied (checked on a Bastion 12.4.3). Save the current text before the first apply if you may want it back (`GET /api/connectionmessages/login_en`, or the `wallix-bastion_connection_message` data source).
- The names are `login_<lang>` and `motd_<lang>`, with `<lang>` among `en`, `fr`, `de`, `es` and `ru`; add a resource per language to translate the texts.
- Use `\n` in the text for a line break.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_connection_message.login_en](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/connection_message) | resource |
| [wallix-bastion_connection_message.motd_en](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/connection_message) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| login\_banner | Text shown before login (English version). | `string` | `"WARNING: Access restricted to authorized users. All sessions are recorded."` | no |
| message\_of\_the\_day | Text shown after login (English version). | `string` | `"Maintenance window every Sunday from 02:00 to 04:00 UTC."` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
