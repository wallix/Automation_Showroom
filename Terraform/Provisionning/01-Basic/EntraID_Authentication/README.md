# Entra ID Authentication

Lets users log in to the Bastion with their Microsoft Entra ID (Azure AD) account. Entra ID signs users in through SAML; the Entra ID authentication domain adds the tenant and an app registration the Bastion uses to talk to Microsoft. Requires a Bastion with API v3.12, an Entra ID tenant and Terraform 1.5 or later.

## What it creates

```text
federation metadata ──> external authentication "<prefix>-saml" (the Bastion as SAML service provider)
                                  │
       authentication domain "<prefix>.entra" (type AzureAD: tenant, client ID and secret)
```

To give Bastion user groups to the members of Entra ID groups, run [Group_Mapping](../Group_Mapping/) with `authdomain_name` set to the `domain_name` output. The user groups then get their access as in the [base](../base/) example.

## Before you start

1. In Entra ID, create an enterprise application with SAML single sign-on, and download its federation metadata XML.
2. Create (or reuse) an app registration with a client secret, and note its application (client) ID and the directory (tenant) ID.
3. After the apply, set the identifier and reply URL of the enterprise application from the `sp_entity_id` and `sp_assertion_consumer_service` outputs.

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

## Run it

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, metadata file, tenant ID, client ID
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_client_secret="<client secret>"

terraform init
terraform apply -var-file=config.tfvars

terraform output                                 # identifier and reply URL for the enterprise application
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The Bastion contacts Microsoft when it creates the domain.** With a tenant or client credentials that Microsoft doesn't accept, the apply fails with `409 ... MissingTokenError('(missing_token) Missing access token parameter.')`. For the same reason, this example was only planned on the test Bastion, not applied.
- **`entity_id` takes the tenant ID**, as described by the Bastion API documentation ("The entity (tenant) ID").
- **The client secret is kept in the Terraform state** (sensitive, not write-only in provider 0.17.0). The resource also has `certificate`, `private_key` and `passphrase` arguments for a client certificate.
- The claim names in `claim_customization` are the default claims of an Entra ID SAML token. The `groups` claim is only sent when the enterprise application is configured to send it.

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
| [wallix-bastion_authdomain_azuread.entra](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authdomain_azuread) | resource |
| [wallix-bastion_externalauth_saml.entra](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/externalauth_saml) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| client\_id | Application (client) ID of the app registration the Bastion uses to read Entra ID. | `string` | n/a | yes |
| client\_secret | Client secret of that app registration. Set it with TF\_VAR\_client\_secret. | `string` | n/a | yes |
| tenant\_id | Directory (tenant) ID of Entra ID. | `string` | n/a | yes |
| auth\_domain\_name | Corporate domain of the users (auth\_domain\_name and default email domain). | `string` | `"example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API. This example requires v3.12 (claim\_customization). | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| federation\_metadata\_file | Federation metadata (XML) of the Entra ID enterprise application, downloaded from its SAML settings. | `string` | `"entra-federationmetadata.xml"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| domain\_name | Entra ID authentication domain, to pass to the Group\_Mapping example (authdomain\_name). |
| sp\_assertion\_consumer\_service | Reply URL (assertion consumer service) to set in the SAML settings of the enterprise application. |
| sp\_entity\_id | Identifier (entity ID) to set in the SAML settings of the enterprise application. |
<!-- END_TF_DOCS -->
