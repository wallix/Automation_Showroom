# TACACS+ Authentication

Lets a Bastion user log in with a password checked by a TACACS+ server, for example the one that already authenticates the administrators of network equipment. TACACS+ is not an authentication domain: it is an external authentication added to the authentication methods (`user_auths`) of each local user. Requires Terraform 1.5 or later.

## What it creates

```text
external authentication "<prefix>-tacacs" (TACACS+ server, port 49, shared secret)
        │
user_auths of the local user "<prefix>-jdoe" (profile user)
```

The user gets no authorization here: add it to a user group linked to target groups as in the [base](../base/) example.

## Run it

Declare the Bastion as a client on the TACACS+ server, with a shared secret. The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, TACACS+ server, user name
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_tacacs_secret="<TACACS+ shared secret>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The user has no password on the Bastion**: `user_auths` only lists the TACACS+ external authentication, so no `password` is set on the user resource.
- **The Bastion doesn't contact the TACACS+ server when Terraform creates the objects**: the example applies with a placeholder host, so a wrong host or secret only shows at the first login.
- **The shared secret is kept in the Terraform state** (sensitive, not write-only in provider 0.17.0).

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
| [wallix-bastion_externalauth_tacacs.server](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_tacacs) | resource |
| [wallix-bastion_user.tacacs](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| tacacs\_secret | TACACS+ shared secret configured for the Bastion on the server. Set it with TF\_VAR\_tacacs\_secret. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| tacacs\_host | IP address or FQDN of the TACACS+ server. | `string` | `"192.0.2.40"` | no |
| user\_name | Login of the Bastion user, checked by the TACACS+ server. null: <prefix>-jdoe. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| external\_authentication | TACACS+ external authentication, to add to the user\_auths of other users. |
| user\_name | Bastion user that authenticates with TACACS+. |
<!-- END_TF_DOCS -->
