# RADIUS as a Second Factor (MFA)

Adds a second factor to the login of directory users: after their LDAP password, the Bastion asks a RADIUS server, typically the front end of an OTP or push solution. The second factor is a setting of the authentication domain (`secondary_auth`), so every user of the domain gets it. Requires Terraform 1.5 or later.

## What it creates

```text
external authentication "<prefix>-ldap"   (first factor: LDAP password)
external authentication "<prefix>-radius" (second factor: RADIUS, port 1812)
        │
authentication domain "<prefix>.ldap": external_auths = [<prefix>-ldap], secondary_auth = [<prefix>-radius]
```

The domain has no group mapping here: add one as in [LDAP_Authentication](../LDAP_Authentication/), then authorizations as in the [base](../base/) example.

## Run it

Declare the Bastion as a RADIUS client on the RADIUS server, with a shared secret. The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, LDAP and RADIUS servers
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_ldap_bind_password="<password of the LDAP bind account>"
export TF_VAR_radius_secret="<RADIUS shared secret>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **`secondary_auth` exists on every authentication domain resource** (LDAP, AD, SAML, OIDC, Entra ID): the same RADIUS external authentication can be added to any of them.
- **The Bastion doesn't contact the RADIUS or LDAP server when Terraform creates the objects**: the example applies with placeholder hosts, so a wrong host or secret only shows at the first login.
- **The RADIUS secret and the bind password are kept in the Terraform state** (sensitive, not write-only in provider 0.17.0).

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
| [wallix-bastion_authdomain_ldap.mfa](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_ldap) | resource |
| [wallix-bastion_externalauth_ldap.directory](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_ldap) | resource |
| [wallix-bastion_externalauth_radius.otp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_radius) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| ldap\_bind\_password | Password of the bind account. Set it with TF\_VAR\_ldap\_bind\_password. | `string` | n/a | yes |
| radius\_secret | RADIUS shared secret configured for the Bastion on the RADIUS server. Set it with TF\_VAR\_radius\_secret. | `string` | n/a | yes |
| auth\_domain\_name | Name of the directory domain (auth\_domain\_name of the Bastion domain). | `string` | `"example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| ldap\_base | Base DN where the Bastion searches the users. | `string` | `"ou=people,dc=example,dc=com"` | no |
| ldap\_bind\_dn | DN of the service account the Bastion binds with. | `string` | `"cn=bastion,ou=services,dc=example,dc=com"` | no |
| ldap\_host | IP address or FQDN of the LDAP server (LDAPS). | `string` | `"ldap.example.com"` | no |
| radius\_host | IP address or FQDN of the RADIUS server (OTP or push server). | `string` | `"192.0.2.30"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| domain\_name | LDAP authentication domain that requires the RADIUS second factor. |
<!-- END_TF_DOCS -->
