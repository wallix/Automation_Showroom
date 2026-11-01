# Active Directory Authentication

Lets the users of an Active Directory domain log in to the Bastion with their domain password, and gives them Bastion user groups from their AD groups. The connection is the same LDAP external authentication as for any directory, flagged as Active Directory; the authentication domain adds the AD specifics. Requires Terraform 1.5 or later.

## What it creates

```text
external authentication "<prefix>-ad" (LDAPS to a domain controller, is_active_directory, sAMAccountName)
        │
authentication domain "<prefix>.ad" (type AD: memberOf, displayName, mail)
        │
mapping: AD group "CN=Bastion Users,..." ──> user group "<prefix>-users" (profile user)
```

The user group gets no authorization here: link it to target groups as in the [base](../base/) example. For a non-AD directory, see [LDAP_Authentication](../LDAP_Authentication/).

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, domain controller, base DN, bind account, group DN
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_ad_bind_password="<password of the bind account>"

terraform init
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **Set the attribute names on the domain.** When `group_attribute`, `display_name_attribute` or `email_attribute` are not set, the Bastion stores them empty (checked through the API); it doesn't fall back to the AD names.
- **`external_group` is the group as AD returns it in `memberOf`**: its full DN, not its name.
- **The Bastion doesn't contact the domain controller when Terraform creates the objects**: the example applies with a placeholder host, so a wrong host or bind account only shows at the first login. The bind password is kept in the Terraform state (sensitive, not write-only).
- **`ad_ca_file` shows a change on every plan with provider 0.17.0**: the Bastion returns the subject of the CA instead of the PEM. Each apply then updates the external authentication with the same CA.

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
| [wallix-bastion_authdomain_ad.corporate](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_ad) | resource |
| [wallix-bastion_authdomain_mapping.ad_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_externalauth_ldap.ad](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_ldap) | resource |
| [wallix-bastion_usergroup.ad_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ad\_bind\_password | Password of the bind account. Set it with TF\_VAR\_ad\_bind\_password. | `string` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| ad\_base | Base DN where the Bastion searches the users. | `string` | `"OU=Users,DC=example,DC=com"` | no |
| ad\_bind\_dn | DN (or user@domain) of the service account the Bastion binds with. | `string` | `"CN=svc-bastion,OU=Service Accounts,DC=example,DC=com"` | no |
| ad\_ca\_file | PEM file of the CA that signed the domain controller certificate. null: no CA sent to the Bastion. | `string` | `null` | no |
| ad\_domain | DNS name of the Active Directory domain. | `string` | `"example.com"` | no |
| ad\_group\_dn | DN of the AD group whose members get the Bastion user group. | `string` | `"CN=Bastion Users,OU=Groups,DC=example,DC=com"` | no |
| ad\_host | IP address or FQDN of a domain controller (or of the domain, for DNS round robin). | `string` | `"dc01.example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| domain\_name | Name of the Active Directory authentication domain on the Bastion. |
| user\_group | Bastion user group given to the members of the AD group. |
<!-- END_TF_DOCS -->
