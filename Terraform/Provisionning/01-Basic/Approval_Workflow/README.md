# Approval Workflow

Access to a critical server on approval: a requester asks for a session or for the password of `root`, an approver accepts or rejects, and the Bastion enforces the answer. The example also restricts the requesters to business hours, makes the password checkout exclusive and time-limited, and lets the approver watch the session.

## What it creates

```text
requester (profile user) ── group "<prefix>-requesters" (timeframe: Mon-Fri 08:00-19:00) ──┐
                                                                                         ├── authorization "<prefix>-critical"
target group "<prefix>-critical" ────────────────────────────────────────────────────────┘     approval: 1 approver, 60 min, comment required
  ├── session account:            root@local@<prefix>-db01:SSH                                   password checkout allowed
  └── password retrieval account: root@local@<prefix>-db01                                       session sharing: view only
                                     └── checkout policy: exclusive, 1 h, +30 min, 2 h max
approver (profile approver) ── group "<prefix>-approvers" (all the time) ── named in the authorization's approvers
```

| Feature | Where | Resource and arguments |
| ------- | ----- | ---------------------- |
| Login hours | `users.tf` | `wallix-bastion_timeframe`, used in `timeframes` of the user group |
| Approval | `authorization.tf` | `approval_required`, `approvers`, `active_quorum`, `inactive_quorum`, `approval_timeout` (minutes) |
| Mandatory comment | `authorization.tf` | `has_comment`, `mandatory_comment` (`has_ticket`, `mandatory_ticket` for a ticket number) |
| Password checkout | `target.tf`, `authorization.tf` | `wallix-bastion_checkout_policy` on the account, `password_retrieval_accounts` in the target group, `authorize_password_retrieval` |
| Session sharing | `authorization.tf` | `authorize_session_sharing`, `session_sharing_mode` (`view_only` or `view_control`) |

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output -json passwords                 # passwords of the requester and the approver
```

To try the workflow, log in as the requester and request the target, then log in as the approver in another browser and accept the request. Outside business hours (Bastion time zone), the timeframe of the requesters group blocks the requester.

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The `root` password is a random placeholder.** The checkout shows it and a session injects it, so set the real password of the account or attach a password change policy to the local domain to have the Bastion rotate it.
- **Checkout durations are in seconds** (`duration`, `extension`, `max_duration`); the approval timeout is in minutes. With `enable_lock = true`, `max_duration` different from `duration` requires an `extension`; the provider checks it at plan.
- **The timeframe has an end date.** After `end_date`, the timeframe blocks the requesters for good: pick dates that fit your use, or use the built-in `allthetime`.

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
| [random_password.root](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.users](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [wallix-bastion_authorization.critical](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_checkout_policy.exclusive](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/checkout_policy) | resource |
| [wallix-bastion_device.critical](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_localdomain.local](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain) | resource |
| [wallix-bastion_device_localdomain_account.root](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain_account) | resource |
| [wallix-bastion_device_localdomain_account_credential.root](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_localdomain_account_credential) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_targetgroup.critical](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_timeframe.business_hours](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/timeframe) | resource |
| [wallix-bastion_user.approver](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_user.requester](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.approvers](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_usergroup.requesters](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

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
| business\_hours | Period during which the requesters can log in (dates YYYY-MM-DD, times HH:MM, Bastion time zone). | ```object({ start_date = string end_date = string start_time = string end_time = string })``` | ```{ "end_date": "2030-12-31", "end_time": "19:00", "start_date": "2026-01-01", "start_time": "08:00" }``` | no |
| target\_account\_login | Login of the privileged account on the critical server. | `string` | `"root"` | no |
| target\_host | IP address or FQDN of the critical SSH server. | `string` | `"192.0.2.20"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| approver | User who approves it. |
| passwords | Passwords of the requester and the approver. |
| requester | User who requests the access (terraform output -json passwords for the passwords). |
<!-- END_TF_DOCS -->
