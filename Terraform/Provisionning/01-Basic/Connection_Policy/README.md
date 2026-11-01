# Connection Policy

A connection policy holds the options of the sessions of one protocol (timeouts, algorithms, startup scenario, file checks...) and the authentication methods allowed on the target. Each service of a device names its policy. The built-in policies (`SSH`, `RDP`...) can't be deleted; to change an option for some servers only, copy a built-in policy, change the option in the copy and set the copy on their services.

## What it creates

```text
built-in policy "SSH" ──read by the data source──> options + authentication methods
                                                         │ merged with: session.inactivity_timeout = 900
                                                         v
connection policy "<prefix>-ssh" <── service SSH of device "<prefix>-srv01"
```

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip, the SSH server, the timeout
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Changing other options

`local.ssh_changes` holds the changes only, section by section, with the names and types the API returns. To see every option of a policy:

```bash
curl -s -H "X-Auth-User: admin" -H "X-Auth-Key: $TF_VAR_bastion_info_token" \
  "https://bastion.example.com/api/connectionpolicies/SSH"
```

For example, the `startup_scenario` section (`enable`, `scenario`, `timeout`...) holds the startup scenario of the SSH sessions.

## Things to know

- **`options` must hold the complete set of options** of the protocol, as the API returns them. A partial set shows a difference on every plan: that's why the example merges its change into the options of the built-in policy.
- **The copy follows the built-in policy.** The data source is read at every plan, so a change to the built-in `SSH` policy (by an administrator, or by a Bastion upgrade that adds options) shows up in the plan of the copy. Review it before applying.
- **`authentication_methods` is copied as well**: the methods of the built-in policy (`PASSWORD_VAULT`, `PUBKEY_VAULT`, `PASSWORD_MAPPING`, `PASSWORD_INTERACTIVE`) stay allowed. Drop the ones you don't want; a target login mode needs its method (see [Target_Login_Modes](../Target_Login_Modes/)).

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
| [wallix-bastion_connection_policy.ssh_timeout](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/connection_policy) | resource |
| [wallix-bastion_device.server](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_connection_policy.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/connection_policy) | data source |

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
| inactivity\_timeout | Value of the inactivity\_timeout option of the SSH sessions in the new policy (0 in the built-in SSH policy). | `number` | `900` | no |
| target\_host | IP address or FQDN of the SSH server that uses the new policy. | `string` | `"192.0.2.10"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| connection\_policy | Connection policy created from the built-in SSH policy. |
| service | Service that uses the policy (device:service). |
<!-- END_TF_DOCS -->
