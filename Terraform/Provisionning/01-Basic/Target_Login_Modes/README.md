# Target Login Modes

A target group doesn't have to hold vault accounts (`session_accounts`, see [base](../base/)). For servers where each person logs in with their own account, the Bastion can reuse the credentials the user logged in to the Bastion with (account mapping), or let the user type them when the session starts (interactive login). A third block, scenario accounts, lists vault accounts that the session can use without logging in with them.

## What it creates

```text
user group "<prefix>" ── authorization (SSH_SHELL_SESSION, recorded) ──┐
                                                                         │
target group "<prefix>" <────────────────────────────────────────────────┘
  ├── session_account_mappings:   <prefix>-srv01:SSH   login and password of the user on the Bastion
  ├── session_interactive_logins: <prefix>-srv01:SSH   login and password typed by the user
  └── session_scenario_accounts:  svc-scenario@<prefix>.lab (global domain, password in the vault)
```

| Block | Who provides the credentials | Arguments |
| ----- | ---------------------------- | --------- |
| `session_accounts` | the vault (account of a domain) | `account`, `domain`, `domain_type`, `device` + `service` or `application` |
| `session_account_mappings` | the user, with the credentials of their Bastion login | `device` + `service`, or `application` |
| `session_interactive_logins` | the user, typed at the start of the session | `device` + `service`, or `application` |
| `session_scenario_accounts` | the vault, for the scenario of the session | `account`, `domain`, `domain_type`; `device` or `application` for a local domain |

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and the SSH server
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

Add Bastion users to the group from `terraform output user_group` to see the targets. Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The connection policy must allow the mode.** The built-in `SSH` policy lists `PASSWORD_MAPPING` and `PASSWORD_INTERACTIVE` in its authentication methods: keep them in a custom policy (see [Connection_Policy](../Connection_Policy/)) used with these blocks.
- **Account mapping suits users whose Bastion login and server login are the same**, such as accounts of the same directory: the Bastion passes on the credentials the user logged in with.
- **Scenario accounts don't open the session.** The REST API describes them as "the devices and applications accounts to use for scenario"; connection policies have a `startup_scenario` option. A global domain account takes neither `device` nor `application`.

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
| [random_password.scenario_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wallix-bastion_authorization.modes](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.server](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_domain.scenario](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.scenario](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.scenario](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_targetgroup.modes](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_usergroup.users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

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
| scenario\_account\_login | Login of the vault account listed as scenario account in the target group. | `string` | `"svc-scenario"` | no |
| target\_host | IP address or FQDN of the SSH server to reach through the Bastion. | `string` | `"192.0.2.10"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| target\_group | Target group holding the three login modes. |
| user\_group | User group authorized on the target group: add the Bastion users to it. |
<!-- END_TF_DOCS -->
