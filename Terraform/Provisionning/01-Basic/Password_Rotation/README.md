# Password Rotation

The Bastion can change the passwords of the accounts it stores on a schedule, so that a password seen once doesn't stay valid. A password change policy sets the shape of the new passwords and when they change; the password change plugin of the domain applies the change on the target system. Here the account is an Active Directory account, changed every week through a domain controller.

## What it creates

```text
password change policy "<prefix>" (20 characters, every character class, @weekly)
        │
global domain "<prefix>.ad" (corp.example.com), plugin "Windows" ──> domain controller 192.0.2.20
  └── account "svc-backup" (auto_change_password = true)
         └── credential: current password of the account (TF_VAR_account_password)
```

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, the AD domain, the domain controller, the account
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_account_password="<current password of the account>"

terraform init
terraform apply -var-file=config.tfvars

terraform output domain_password_change          # true: the domain is set up for the rotation
```

The Bastion then changes the password on the schedule of the policy (`change_period`). Clean up with `terraform destroy -var-file=config.tfvars`.

## Plugins

`password_change_plugin` is the name of a plugin shipped with the Bastion (`Windows`, `Unix`, `LDAP`, `Cisco`, `MySQL`, `Oracle`...) and `password_change_plugin_parameters` holds its parameters, which depend on the plugin and on the kind of domain. The REST API lists both (API v3.12):

```bash
curl -s -H "X-Auth-User: admin" -H "X-Auth-Key: $TF_VAR_bastion_info_token" \
  "https://bastion.example.com/api/passwordchangeplugins?parameters=true"
```

For the local accounts of one server (`root` on a Linux host), put the same four arguments on a `wallix-bastion_device_localdomain` instead, for example with the `Unix` plugin.

## Things to know

- **`auto_change_password` is `false` by default with this provider**, while the Bastion enables it on an account created in the web UI. Without it the account stays out of the rotation even though its domain has a policy.
- **Terraform doesn't read the password back.** After a rotation the state still holds the first password and the plan shows no change. Changing `account_password` later replaces the password in the vault only.
- **To set a password of your choice on the target as well**, add `propagate_credential_change = true` to the credential: the Bastion changes it on the target through the plugin of the domain. The target must be reachable at apply time; when the propagation fails, the credential is tainted and replaced on the next apply.
- **`admin_account`** (the account the plugin uses to change the passwords) must already exist when it is set on the domain, so it takes a second apply: the first one creates the domain and the account.

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
| [wallix-bastion_domain.ad](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.svc](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.svc](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_passwordchangepolicy.weekly](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/passwordchangepolicy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_password | Current password of the account, stored in the vault until the first rotation. Pass it with TF\_VAR\_account\_password. | `string` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| account\_login | Login of the AD account whose password the Bastion rotates. | `string` | `"svc-backup"` | no |
| ad\_domain\_name | Name of the Active Directory domain holding the account. | `string` | `"corp.example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| domain\_controller | IP address or FQDN of the domain controller the Bastion changes the password on. | `string` | `"192.0.2.20"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account | Account whose password the Bastion rotates (account@domain). |
| domain\_password\_change | true when the domain of the account has a password change configured, the condition for the rotation. |
| password\_change\_policy | Password change policy used by the domain. |
<!-- END_TF_DOCS -->
