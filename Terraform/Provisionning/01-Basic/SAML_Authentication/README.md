# SAML Authentication

Lets users log in to the Bastion through a SAML 2.0 identity provider (ADFS, Okta, Keycloak...), and gives them Bastion user groups from the groups sent in the SAML assertion. Requires a Bastion with API v3.12 and Terraform 1.5 or later.

## What it creates

```text
idp-metadata.xml ──> external authentication "<prefix>-saml" (the Bastion as SAML service provider)
                              │
          authentication domain "<prefix>.saml" (login choice "Corporate SSO (<prefix>)")
                              │
          mapping: IdP group "bastion-users" ──> user group "<prefix>-users" (profile user)
```

The user group gets no authorization here: link it to target groups as in the [base](../base/) example. For Entra ID, see [EntraID_Authentication](../EntraID_Authentication/); for OpenID Connect, [OIDC_Authentication](../OIDC_Authentication/).

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
# Download the SAML metadata of the identity provider to idp-metadata.xml
cp config.tfvars.example config.tfvars           # set the Bastion, attribute names, group
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output                                 # register sp_entity_id and sp_assertion_consumer_service on the IdP
```

Then open the Bastion login page: the `label` of the domain appears as a login choice.

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **`claim_customization` is required with API v3.12** (and refused with v3.8): the provider checks it at plan. Its values are attribute names of the SAML assertion; `group` is needed for the mappings, and `external_group` must match the group value the identity provider sends.
- **`sp_entity_id` and the assertion consumer service use the FQDN of the Bastion**, while `idp_initiated_url` is built from the address Terraform used to reach the API (`bastion_info_ip`).
- **The example doesn't output `sp_metadata`.** The Bastion generates it on each read with a new `validUntil` date, so an output of it changes on every plan. `terraform state show wallix-bastion_externalauth_saml.idp` displays it when an identity provider needs the file.

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
| [wallix-bastion_authdomain_mapping.idp_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_authdomain_saml.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_saml) | resource |
| [wallix-bastion_externalauth_saml.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_saml) | resource |
| [wallix-bastion_usergroup.idp_users](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| auth\_domain\_name | Name of the corporate domain (auth\_domain\_name of the Bastion domain). | `string` | `"example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API. This example requires v3.12 (claim\_customization). | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| idp\_group | Group, as sent by the identity provider in the group attribute, whose members get the Bastion user group. | `string` | `"bastion-users"` | no |
| idp\_metadata\_file | SAML metadata (XML) of the identity provider, downloaded from it. | `string` | `"idp-metadata.xml"` | no |
| saml\_attributes | Attributes of the SAML assertion holding the user name, display name, email and groups. | ```object({ username = string displayname = optional(string) email = optional(string) group = optional(string) })``` | ```{ "displayname": "displayname", "email": "email", "group": "groups", "username": "username" }``` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| idp\_initiated\_url | URL for a login started from the identity provider portal. |
| sp\_assertion\_consumer\_service | Assertion consumer service (reply URL) of the Bastion, to register on the identity provider. |
| sp\_entity\_id | Entity ID of the Bastion, to register on the identity provider. |
<!-- END_TF_DOCS -->
