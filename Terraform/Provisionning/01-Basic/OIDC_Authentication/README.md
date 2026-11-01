# OIDC Authentication

Lets users log in to the Bastion with an OpenID Connect identity provider (Entra ID, Keycloak, Okta...), and gives them Bastion user groups and profiles from their groups at the identity provider. Requires a Bastion with API v3.12, provider 0.17.0 or later and Terraform 1.11 or later.

## What it creates

```text
discovery document (read over HTTPS) ──> external authentication "corporate_oidc" (OIDC client of the Bastion)
                                                  │
                     authentication domain "corporate.oidc" (shown on the login page)
                                                  │
              mapping: IdP group "bastion-admins" ──> user group "OIDC_Administrators" (profile product_administrator)
              mapping: IdP group "bastion-users"  ──> user group "OIDC_Users" (profile user)
```

The user groups get no authorization here: link them to target groups as in the [base](../base/) example.

## Before you start

1. Register the Bastion as a client (confidential, authorization code flow) on the identity provider, and note its client ID and secret.
2. Configure the identity provider to send the user's groups in a claim of the ID token (`groups` by default). Without it, users can log in but get no Bastion group.
3. Check that the machine running Terraform can reach the discovery URL: Terraform reads it to fill the endpoints of the identity provider, which the Bastion doesn't fetch by itself at creation.

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

## Run it

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, discovery URL, client ID, domain
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_oidc_client_secret="<client secret>"

terraform init
terraform apply -var-file=config.tfvars

terraform output redirect_uri                    # register it on the identity provider
```

Then open the Bastion login page: the `label` of the domain appears as a login choice.

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The client secret never reaches the state.** `client_secret_wo` is a write-only argument and `oidc_client_secret` an ephemeral variable, so the secret is neither in the state nor in a saved plan. Terraform can't see when it changes: to rotate it, set the new secret and increase `oidc_client_secret_version`.
- **The group claim value depends on the identity provider.** Entra ID sends group object IDs (a GUID), Keycloak sends group names or paths. `idp_group` must match exactly what the provider sends.
- **Order matters on destroy.** The Bastion refuses to delete an external authentication still used by a domain; the reference between the two resources makes Terraform destroy the domain first.
- **Some changes replace the external authentication** (`redirect_uri`, removing `oidc_advanced_attributes`). While the domain still uses it, that replacement fails with a 409: remove it from the domain first, apply, then make the change.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| http | ~> 3.6 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_authdomain_mapping.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_mapping) | resource |
| [wallix-bastion_authdomain_oidc.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_oidc) | resource |
| [wallix-bastion_externalauth_oidc.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_oidc) | resource |
| [wallix-bastion_usergroup.idp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [http_http.oidc_discovery](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| authdomain | OIDC authentication domain. label is shown on the login page; default\_language is one of de, en, es, fr, ru. | ```object({ domain_name = string auth_domain_name = string label = string default_email_domain = string default_language = optional(string, "en") })``` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| oidc\_client\_id | Client ID of the Bastion, registered on the identity provider. | `string` | n/a | yes |
| oidc\_client\_secret | Client secret of the Bastion. Ephemeral: never written to the state or a plan file. | `string` | n/a | yes |
| oidc\_discovery\_url | URL of the OpenID Provider metadata, ending with /.well-known/openid-configuration. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API. OIDC requires v3.12. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| group\_mappings | Bastion user group => identity provider group (group claim value) and Bastion profile. | ```map(object({ idp_group = string profile = optional(string, "user") }))``` | ```{ "OIDC_Administrators": { "idp_group": "bastion-admins", "profile": "product_administrator" }, "OIDC_Users": { "idp_group": "bastion-users" } }``` | no |
| oidc\_claims | Claims of the ID token holding the user attributes. group is needed for the group mappings. | ```object({ username = string group = optional(string) email = optional(string) displayname = optional(string) })``` | ```{ "displayname": "name", "email": "email", "group": "groups", "username": "preferred_username" }``` | no |
| oidc\_client\_secret\_version | Increase it to send a new oidc\_client\_secret to the Bastion (rotation). | `number` | `1` | no |
| oidc\_name | Name of the OIDC external authentication on the Bastion. | `string` | `"corporate_oidc"` | no |
| oidc\_scopes | Scopes requested from the identity provider. | `list(string)` | ```[ "openid", "profile", "email" ]``` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| authdomain\_id | ID of the OIDC authentication domain on the Bastion. |
| issuer | Issuer read from the discovery document. |
| redirect\_uri | Redirection URI to register on the identity provider for the client. |
<!-- END_TF_DOCS -->
