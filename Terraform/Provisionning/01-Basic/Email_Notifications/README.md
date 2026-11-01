# Email Notifications

The Bastion can send an email when a system or security event occurs (`wrong_fingerprint`, `integrity_error`, `filesystem_full`...). This takes two resources: the SMTP relay the Bastion sends through, set once per Bastion, and a notification that lists the events and the recipients.

## What it creates

```text
SMTP settings (Bastion-wide) ── smtp.example.com:587, STARTTLS, no authentication

notification "<prefix>-secops" ── email to secops@example.com
     └── events: wrong_fingerprint, integrity_error, filesystem_full, licence_notifications
```

The notification name starts with a random prefix (`notif-<adjective>-<animal>`), so the example can run several times on a shared Bastion.

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, the SMTP relay, the recipients
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_smtp_password="<password>"         # only for a relay with authentication

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`: it deletes the notification and leaves the SMTP settings as they are.

## Things to know

- **The SMTP settings are Bastion-wide.** The apply replaces the current ones, and destroy only removes them from the state (the API can't delete them). To see what would change first, import them and read the plan: `terraform import -var-file=config.tfvars wallix-bastion_config_smtp.main smtpConfig`.
- **The SMTP password is never read back**, so Terraform can't see a change made in the web UI. It is in the state, as a sensitive value.
- **Events** are checked at plan, among `cx_equipment`, `daily_reporting`, `disk_space_critical`, `external_storage_full`, `filesystem_full`, `integrity_error`, `licence_notifications`, `new_fingerprint`, `password_expired`, `pattern_found`, `primary_cx_failed`, `raid_error`, `rdp_outcxn_found`, `rdp_pattern_found`, `rdp_process_found`, `secondary_cx_failed`, `sessionlog_purge`, `watchdog_notifications` and `wrong_fingerprint`. An update replaces the whole list.

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
| [wallix-bastion_config_smtp.main](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/config_smtp) | resource |
| [wallix-bastion_notification.secops](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/notification) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| smtp\_server | IP address or FQDN of the SMTP relay. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| events | Events that send the notification (names checked at plan, see the README). | `list(string)` | ```[ "wrong_fingerprint", "integrity_error", "filesystem_full", "licence_notifications" ]``` | no |
| postmaster\_email | Address that receives the emails of the local services of the Bastion. | `string` | `"postmaster@example.com"` | no |
| recipients | Addresses that receive the notification. | `list(string)` | ```[ "secops@example.com" ]``` | no |
| sender\_email | Sender address of the emails sent by the Bastion. | `string` | `"bastion@example.com"` | no |
| sender\_name | Display name of the emails sent by the Bastion. | `string` | `"WALLIX Bastion"` | no |
| smtp\_authentication\_method | off (no authentication), on, plain, login, SCRAM-SHA-1, CRAM-MD5, DIGEST-MD5 or ntlm. | `string` | `"off"` | no |
| smtp\_password | Password of smtp\_user. Set it with TF\_VAR\_smtp\_password. | `string` | `null` | no |
| smtp\_port | Port of the SMTP relay. | `number` | `587` | no |
| smtp\_protocol | smtp, smtps or starttls. | `string` | `"starttls"` | no |
| smtp\_user | User of the SMTP relay, when it requires authentication. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| notification\_name | Notification created by the example. |
<!-- END_TF_DOCS -->
