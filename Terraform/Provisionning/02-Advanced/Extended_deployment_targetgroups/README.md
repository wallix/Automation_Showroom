# Extended deployment: target groups and authorizations

A complete Bastion configuration built from one inventory file per type of object: connection policies, timeframes, servers and their services, accounts, target groups, user groups, users and authorizations. Read the [inventory introduction](../Using_Inventory/README.md) for how Terraform reads YAML inventories; this example splits the inventory by object type, where the use cases keep it in one file.

## What it creates

```text
inventory/                    Bastion objects
connection_policies.yaml  ─>  7 connection policies (copies of the built-in SSH, RDP, TELNET and RAWTCPIP policies)
timeframes.yaml           ─>  2 timeframes
devices.yaml              ─>  5 servers, 9 services, each using a connection policy
domains.yaml              ─>  4 global domains
target_accounts.yaml      ─>  10 accounts, each used on some services of one server (placeholder passwords)
target_groups.yaml        ─>  7 target groups, filled with the accounts that list them
groups.yaml, users.yaml   ─>  7 user groups (with their timeframes), 4 users
authorizations.yaml       ─>  10 authorizations, one user group on one target group each
```

An account declares where it is used and which target groups it belongs to:

```yaml
target_accounts:
  db_admin:
    login: "dbadmin"
    domain_name: "database_domain"
    device_name: "db-server-01"
    services: ["ssh", "mysql"]                 # ids of the device services
    target_groups: ["database_servers", "critical_infrastructure"]
```

From it, Terraform attaches the account to `db-server-01:SSH_Access` and `db-server-01:MySQL_Database`, adds a session for each service to both target groups, and lets their members check the password out when the authorization allows it.

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform plan -var-file=config.tfvars           # review what the inventory produces
terraform apply -var-file=config.tfvars

terraform output target_groups                   # targets of each target group
terraform output -json user_passwords            # users change it at first login
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **A connection policy needs its complete set of options**, otherwise every plan shows a difference. Each policy copies the options of the built-in policy of its protocol (data source) and overrides the sections given in the inventory, here `session.inactivity_timeout`.
- **One authorization links one user group to one target group**: to give a group access to two target groups, write two authorizations. Approvers and quorums are only sent when `approval_required` is true.
- **References give the order of creation and destruction**: a service uses its policy, an account its services, a target group its accounts. The Bastion refuses to delete a policy still used by a service, so the order matters on destroy.
- **The account passwords are random placeholders** kept in the Terraform state: set the real ones, or attach a password change policy to the domains (see [Password_Rotation](../../01-Basic/Password_Rotation/)).

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
| [random_password.accounts](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.users](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [wallix-bastion_authorization.authorizations](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_connection_policy.policies](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/connection_policy) | resource |
| [wallix-bastion_device.devices](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.services](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_domain.domains](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.accounts](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.passwords](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_targetgroup.target_groups](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_timeframe.timeframes](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/timeframe) | resource |
| [wallix-bastion_user.users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.groups](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_connection_policy.builtin](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/connection_policy) | data source |

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

## Outputs

| Name | Description |
| ---- | ----------- |
| authorizations | User group and target group of each authorization. |
| target\_groups | Targets of each target group: account@domain@device:service. |
| user\_passwords | Bastion password of each user (terraform output -json user\_passwords); users change it at first login. |
<!-- END_TF_DOCS -->
