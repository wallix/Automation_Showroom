# LDAP Authentication

Lets the users of an LDAP directory log in to the Bastion with their directory password, without creating them one by one: their Bastion user groups come from their LDAP groups. Requires Terraform 1.5 or later.

## What it creates

```text
external authentication "<prefix>-ldap" (LDAPS connection, bind account, search base)
        │
authentication domain "<prefix>.ldap" (attributes read on the user entry: memberOf, cn, mail)
        │
mapping: LDAP group "cn=bastion-users,..." ──> user group "<prefix>-users" (profile user)
```

The user group gets no authorization here: link it to target groups as in the [base](../base/) example.

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, LDAP server, base DN, bind DN, group DN
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_ldap_bind_password="<password of the bind account>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The Bastion doesn't contact the LDAP server when Terraform creates the objects.** The example applies with a placeholder host: a wrong host, bind DN or password only shows when a user logs in.
- **The bind password is in the Terraform state** (sensitive, but not write-only in provider 0.17.0). Without `is_anonymous_access = true`, the provider requires both `login` and `password`.
- **`external_group` is the group as the directory returns it** in `group_attribute`: with `memberOf`, the full DN of the group. OpenLDAP only returns `memberOf` with the memberOf overlay.
- **`ldap_ca_file` (the `ca_certificate` of the LDAP server) shows a change on every plan with provider 0.17.0**: the Bastion returns the subject of the CA instead of the PEM, and the provider compares the two. Each apply then updates the external authentication with the same CA.

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
| [wallix-bastion_authdomain_ldap.corporate](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_ldap) | resource |
| [wallix-bastion_authdomain_mapping.ldap_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_externalauth_ldap.corporate](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_ldap) | resource |
| [wallix-bastion_usergroup.ldap_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| ldap\_bind\_password | Password of the bind account. Set it with TF\_VAR\_ldap\_bind\_password. | `string` | n/a | yes |
| auth\_domain\_name | Name of the directory domain (auth\_domain\_name of the Bastion domain). | `string` | `"example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| ldap\_base | Base DN where the Bastion searches the users. | `string` | `"ou=people,dc=example,dc=com"` | no |
| ldap\_bind\_dn | DN of the service account the Bastion binds with. | `string` | `"cn=bastion,ou=services,dc=example,dc=com"` | no |
| ldap\_ca\_file | PEM file of the CA that signed the LDAP server certificate. null: no CA sent to the Bastion. | `string` | `null` | no |
| ldap\_group\_dn | DN of the LDAP group whose members get the Bastion user group. | `string` | `"cn=bastion-users,ou=groups,dc=example,dc=com"` | no |
| ldap\_host | IP address or FQDN of the LDAP server. | `string` | `"ldap.example.com"` | no |
| ldap\_port | LDAPS port of the LDAP server. | `number` | `636` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| domain\_name | Name of the LDAP authentication domain on the Bastion. |
| user\_group | Bastion user group given to the members of the LDAP group. |
<!-- END_TF_DOCS -->
