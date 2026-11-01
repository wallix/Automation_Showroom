# Tags and Data Sources

Tags are key/value labels on devices and applications, to sort them by environment, owner or anything else. Data sources read objects that already exist on the Bastion and that Terraform doesn't manage; the provider has one for almost every resource. This example gives an existing user group access to a new tagged server.

## What it creates

```text
user group "<existing_user_group>" (existing, read by a data source)
     └── authorization "<prefix>-web" (SSH shell, recorded)
            └── target group "<prefix>-web" (interactive login)
                   └── device "<prefix>-web01", tags environment=production, owner=web-team
                          └── service SSH (port 22)
```

Every object name starts with a random prefix (`tags-<adjective>-<animal>`), so the example can run several times on a shared Bastion. The user group is not created, changed or deleted by Terraform.

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and existing_user_group
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output existing_group_members          # users who can now open the server
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The tags of the configuration replace those of the device**: a tag added outside Terraform is removed by the next apply. Add `lifecycle { ignore_changes = [tags] }` to the device if another tool manages its tags.
- **A data source fails at plan when the object doesn't exist**, so a wrong `existing_user_group` stops the plan before any change.
- `session_interactive_logins` uses no account from the vault: the target group only names the device and the service.
- `wallix-bastion_application` takes the same `tags` blocks.

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
| [wallix-bastion_authorization.web](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.web](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_targetgroup.web](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_usergroup.existing](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/usergroup) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| existing\_user\_group | Name of a user group that already exists on the Bastion: its members get access to the new server. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| target\_host | IP address or FQDN of the SSH server to declare. | `string` | `"192.0.2.20"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| device\_tags | Tags of the new device. |
| existing\_group\_members | Members of the existing user group, read by the data source: they can now open the server. |
<!-- END_TF_DOCS -->
