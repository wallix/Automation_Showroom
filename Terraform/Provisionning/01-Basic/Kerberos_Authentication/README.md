# Kerberos Authentication

Lets a Bastion user authenticate with a Kerberos ticket of the corporate realm (Active Directory or MIT Kerberos) instead of a password stored on the Bastion. The Bastion holds a keytab of its service principal; a user can authenticate with Kerberos once the Kerberos external authentication is in its authentication methods. Requires Terraform 1.5 or later.

## What it creates

```text
bastion.keytab ──> external authentication "<prefix>-kerberos" (realm EXAMPLE.COM, KDC on port 88)
                            │
                  user_auths of the local user "<prefix>-jdoe" (profile user)
```

The user gets no authorization here: add it to a user group linked to target groups as in the [base](../base/) example.

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
# Export the keytab of the Bastion service principal from the KDC to bastion.keytab
cp config.tfvars.example config.tfvars           # set the Bastion, KDC, realm, user name
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The keytab is checked at creation**: a file that isn't a keytab fails with `400 ... keytab: A valid keytab file is required`. It is sent base64 encoded (`filebase64`) and kept in the Terraform state (sensitive). The API lists the principals it found in the keytab (`principal_list` in `GET /api/externalauths`); the provider doesn't expose them.
- **Every update of the external authentication sends the keytab again** and replaces the one on the Bastion: keys added outside of Terraform are lost (provider documentation).
- **`kerberos_password = true`** creates a `KERBEROS-PASSWORD` external authentication instead of `KERBEROS`. Changing it replaces the resource.
- The REST API also accepts a Kerberos ticket (`POST /api/kerberos`) from a user that has this external authentication in its `user_auths` (API documentation).

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
| [wallix-bastion_externalauth_kerberos.realm](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_kerberos) | resource |
| [wallix-bastion_user.kerberos](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |

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
| kdc\_host | IP address or FQDN of the KDC (a domain controller for Active Directory). | `string` | `"kdc.example.com"` | no |
| keytab\_file | Keytab of the Bastion service principal, exported from the KDC. | `string` | `"bastion.keytab"` | no |
| realm | Kerberos realm, usually the domain name in uppercase. | `string` | `"EXAMPLE.COM"` | no |
| user\_name | Login of the Bastion user that authenticates with Kerberos. null: <prefix>-jdoe. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| external\_authentication | Kerberos external authentication, to add to the user\_auths of other users. |
| user\_name | Bastion user that authenticates with Kerberos. |
<!-- END_TF_DOCS -->
