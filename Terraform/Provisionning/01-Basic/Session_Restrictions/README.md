# Session Restrictions

The Bastion watches what the user does during a session and reacts when it matches a rule: `kill` disconnects the session, `notify` sends a notification and lets the session go on. Restrictions are set on a target group (every session on its targets) or on a user group (every session of its members), and apply to one subprotocol each.

## What it creates

```text
user group "<prefix>"  ── restriction: notify on "sudo"     (SSH_SHELL_SESSION) ──┐
                                                                                   ├── authorization (SSH_SHELL_SESSION, recorded)
target group "<prefix>" ── restriction: kill on "rm -rf /"  (SSH_SHELL_SESSION) ──┘
  └── interactive login on device "<prefix>-srv01", service SSH
```

The target group uses an interactive login (the user types the server credentials) only to keep the example short: restrictions work the same with vault accounts.

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and the SSH server
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

Add Bastion users to the group from `terraform output user_group`, open an SSH session on the target and type a `sudo` command to trigger the notification. Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **`action`** is `kill` or `notify`, and **`subprotocol`** one of `SSH_SHELL_SESSION`, `SSH_REMOTE_COMMAND`, `SSH_SCP_UP`, `SSH_SCP_DOWN`, `SFTP_SESSION`, `RLOGIN`, `TELNET` and `RDP`. The provider checks both at plan.
- **`rules`** is the user action that triggers the restriction (here a command typed in the shell). Test a rule on a lab server before relying on it.
- **The subprotocol must be allowed in the session**: enabled on the service and in the authorization, as `SSH_SHELL_SESSION` is here.

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
| [wallix-bastion_authorization.operators](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.server](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_targetgroup.servers](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_usergroup.operators](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

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
| target\_host | IP address or FQDN of the SSH server to reach through the Bastion. | `string` | `"192.0.2.10"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| target\_group | Target group with the kill restriction. |
| user\_group | User group with the notify restriction: add the Bastion users to it. |
<!-- END_TF_DOCS -->
