# Encryption

The encryption of the Bastion can be protected by a passphrase, which then has to be entered after each reboot: the Bastion stays `sealed` until it is. This example brings the encryption of a running Bastion under Terraform and changes its passphrase.

## What it creates

Nothing new: the encryption is set up when the Bastion is installed, so Terraform imports it.

```text
encryption of the Bastion (singleton, id "encryption")
  ├── import block: taken over, no setup request
  └── new_passphrase changed: sends current_passphrase -> new_passphrase

data source wallix-bastion_encryption: seal_state, encryption_mode (outputs)
```

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # then set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_current_passphrase="<current passphrase>"
export TF_VAR_new_passphrase="<current passphrase>"   # same value on the first run

terraform init
terraform plan -var-file=config.tfvars           # read it before applying
terraform apply -var-file=config.tfvars
```

The API never returns the passphrase, so the imported state has none. On a Bastion with a passphrase, the first plan therefore shows an update, which sends the current passphrase as the new one. On a Bastion without a passphrase, keep both variables empty (`""`): the plan only shows the import.

To change the passphrase, set `TF_VAR_new_passphrase` to the new one and apply. Then set `TF_VAR_current_passphrase` to the new one too: changing only `current_passphrase` sends nothing.

## Things to know

- **Creating the resource only works on a fresh install** (`seal_state = need_setup`). On a Bastion already set up, the creation fails without sending any request: hence the `import` block.
- **A Bastion set up without a passphrase** (`encryption_mode = unprotected`) can't get one afterwards: a non-empty `new_passphrase` fails with `400 Cannot change passphrase in security level 0`, according to the provider documentation.
- **The passphrases are in the Terraform state** (sensitive values). A lost passphrase means a sealed Bastion that can't be unsealed: keep it in a secret manager as well.
- Tested with a plan only, on a Bastion 12.4.3 without a passphrase: `1 to import, 0 to change`. Destroy only removes the resource from the state.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_encryption.main](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/encryption) | resource |
| [wallix-bastion_encryption.current](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/encryption) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| current\_passphrase | Current encryption passphrase of the Bastion. Empty string for a Bastion set up without one. | `string` | n/a | yes |
| new\_passphrase | Passphrase to set. Equal to current\_passphrase: no change. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| encryption\_mode | need\_setup, unprotected (no passphrase) or passphrase. |
| seal\_state | need\_setup, sealed (passphrase to enter, e.g. after a reboot) or unsealed. |
<!-- END_TF_DOCS -->
