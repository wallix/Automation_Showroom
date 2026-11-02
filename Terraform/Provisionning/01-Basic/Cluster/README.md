# Cluster

A cluster groups several targets that can do the same job, such as the Windows jump servers (RDS) that run a published application. A standard application names the cluster as its `target`, with the program to start on each member (`paths`), instead of a single jump server.

[UseCase1](../../02-Advanced/Using_Inventory/UseCase1%20-%20OneAuthorizationPerUser/) publishes applications on one jump server; this example puts two behind a cluster.

## What it creates

```text
account "svc-rds" (global domain "<prefix>.lab", password in the vault)
  ├── used on device "<prefix>-rds01", service RDP ──┐
  └── used on device "<prefix>-rds02", service RDP ──┤
                                                     v
cluster "<prefix>-rds": svc-rds@<prefix>.lab@<prefix>-rds01:RDP, svc-rds@<prefix>.lab@<prefix>-rds02:RDP
  ^
  └── application "<prefix>" (standard, policy RDP)
        paths: notepad.exe on rds01, notepad.exe on rds02
```

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, the jump servers, the account, the program
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

To open the application, give it an account and authorize a user group on it, as UseCase1 does. Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **A cluster member is a target** in one of three forms: `accounts` (`account@domain@device:service`, a vault account), `account_mappings` or `interactive_logins` (`device:service`). The target must exist: here the account lists both services in its `resources`. The provider documentation writes `account@domain:device:service`, which the Bastion refuses (`Account target ... not found`).
- **One `paths` block per member**, whose `target` is the member: the program and its `working_dir` can differ from one jump server to the other.
- **Placeholders.** The jump servers, the account password (random) and the program (`notepad.exe`) are demo values: set the real ones, and install the program on every member.

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
| [random_password.rds_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wallix-bastion_application.app](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application) | resource |
| [wallix-bastion_cluster.rds](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/cluster) | resource |
| [wallix-bastion_device.rds01](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device.rds02](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.rds01](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_device_service.rds02](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_domain.rds](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.rds](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.rds](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |

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
| jump\_account\_login | Login of the account that opens the RDP session on the jump servers. | `string` | `"svc-rds"` | no |
| jump\_server\_hosts | IP addresses or FQDNs of the two Windows jump servers (RDS) of the cluster. | `list(string)` | ```[ "192.0.2.31", "192.0.2.32" ]``` | no |
| program | Program the application runs on the jump servers. | `string` | `"C:\\Windows\\System32\\notepad.exe"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| application | Standard application whose target is the cluster. |
| cluster | Cluster of jump servers. |
| cluster\_members | Targets of the cluster (account@domain@device:service). |
<!-- END_TF_DOCS -->
