# Delegated Administration

A profile sets what a Bastion user can do in the web UI and the REST API. A custom profile limited to some user groups and target groups lets a team lead manage the users of their team without seeing the rest of the Bastion.

## What it creates

```text
profile "<prefix>-admin"
  ├── users, user groups: modify
  ├── devices, target groups, authorizations: view
  ├── no access to the targets (target_access = false)
  └── limited to: user group "<prefix>-team", target group "<prefix>-servers"

user "<prefix>-admin" (local password) ──profile──> "<prefix>-admin"
```

Every object name starts with a random prefix (`deleg-<adjective>-<animal>`), so the example can run several times on a shared Bastion.

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # then set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output -raw admin_password             # password of the delegated administrator
```

Call the REST API as the new administrator to see the limitation: `/api/usergroups` and `/api/targetgroups` return only the two groups of the example, and creating a device is refused (`403`), since devices are `view` only.

```bash
curl -u "<admin_user_name>:<admin_password>" https://bastion.example.com/api/usergroups
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- `gui_features` takes `view` or `modify` per feature (`execute` for `backup` and `credential_recovery`); a feature left out is not granted.
- `gui_transmission` is required by the provider. The built-in profiles that can't edit profiles (`auditor`, `user`) have it empty, as here.
- Without `default_target_group` in `target_groups_limitation`, the Bastion takes the first of `target_groups`.
- The password of the administrator is random and kept in the Terraform state. Treat the state as a secret.

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
| [random_password.team_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wallix-bastion_profile.team_admin](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/profile) | resource |
| [wallix-bastion_targetgroup.team](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_user.team_admin](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.team](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| admin\_email | Email address of the delegated administrator. | `string` | `"team-admin@example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| admin\_password | Password of the delegated administrator (terraform output -raw admin\_password). |
| admin\_user\_name | Delegated administrator created by the example. |
| managed\_groups | The only user group and target group the administrator can reach. |
<!-- END_TF_DOCS -->
