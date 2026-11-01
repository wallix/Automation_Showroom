# Provisioning a Bastion with Terraform

These examples configure a WALLIX Bastion that is already running (users, targets, accounts, authorizations, authentication, settings) with the [`wallix/wallix-bastion`](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs) Terraform provider. To install the Bastion itself, see [Deploying](../Deploying/).

Each folder is a standalone Terraform configuration showing one feature with as few resources as possible. Start with [base](01-Basic/base/), then open the example of the feature you need and copy it.

## Examples

### Start here

| Example | What it shows | Requires |
| ------- | ------------- | -------- |
| [base](01-Basic/base/) | The smallest complete access: user, server, vault account, target group, authorization | |

### Access to targets

| Example | What it shows | Requires |
| ------- | ------------- | -------- |
| [Target_Login_Modes](01-Basic/Target_Login_Modes/) | Account mapping, interactive login and scenario accounts in a target group | |
| [Session_Restrictions](01-Basic/Session_Restrictions/) | Kill or notify on a command typed in a session, set on a target group and on a user group | |
| [Connection_Policy](01-Basic/Connection_Policy/) | A copy of the built-in SSH policy with one option changed, set on a service | |
| [Approval_Workflow](01-Basic/Approval_Workflow/) | Access on approval, password checkout, login hours, session sharing | |
| [Web_Application](01-Basic/Web_Application/) | A web application opened through the Bastion, with automatic login | API v3.12 |
| [Application_Local_Account](01-Basic/Application_Local_Account/) | An account that exists only in one web application, used by a target group | API v3.12 |
| [Cluster](01-Basic/Cluster/) | A standard application run on a cluster of two jump servers | |
| [Tags_and_Data_Sources](01-Basic/Tags_and_Data_Sources/) | A tagged server opened to an existing user group read by a data source | An existing user group |

### Accounts and credentials

| Example | What it shows | Requires |
| ------- | ------------- | -------- |
| [Password_Rotation](01-Basic/Password_Rotation/) | Weekly password rotation of an AD account by the Bastion: password change policy, domain plugin, `auto_change_password` | |
| [SSH_Certificates](01-Basic/SSH_Certificates/) | The Bastion signs the SSH keys of a domain's accounts; servers trust its CA public key | |
| [Certificate_Authority](01-Basic/Certificate_Authority/) | SSH and X.509 certificate authorities of your PKI declared on the Bastion | API v3.12 |

### User authentication

| Example | What it shows | Requires |
| ------- | ------------- | -------- |
| [LDAP_Authentication](01-Basic/LDAP_Authentication/) | Login with an LDAP directory, LDAP group mapped to a Bastion user group | |
| [AD_Authentication](01-Basic/AD_Authentication/) | Login with Active Directory, AD group mapped to a Bastion user group | |
| [OIDC_Authentication](01-Basic/OIDC_Authentication/) | Login with an OpenID Connect identity provider, IdP groups mapped to Bastion groups | API v3.12, Terraform 1.11 |
| [SAML_Authentication](01-Basic/SAML_Authentication/) | Login with a SAML 2.0 identity provider, IdP group mapped to a Bastion user group | API v3.12 |
| [EntraID_Authentication](01-Basic/EntraID_Authentication/) | Entra ID authentication domain (SAML and app registration) | API v3.12, an Entra ID tenant |
| [Group_Mapping](01-Basic/Group_Mapping/) | Bastion user groups and mappings built from an Entra ID group export | An Entra ID authentication domain |
| [Kerberos_Authentication](01-Basic/Kerberos_Authentication/) | Kerberos realm with a keytab, used by a local user | A keytab of the Bastion |
| [RADIUS_MFA](01-Basic/RADIUS_MFA/) | RADIUS server as second factor of an LDAP authentication domain | |
| [TACACS_Authentication](01-Basic/TACACS_Authentication/) | Local user whose password is checked by a TACACS+ server | |
| [X509_Authentication](01-Basic/X509_Authentication/) | User certificate login, with CRL and OCSP revocation checks | Changes the listener certificate |

### Administration and Bastion settings

The examples marked "Bastion-wide" change a setting of the whole Bastion: apply them on a test Bastion first.

| Example | What it shows | Requires |
| ------- | ------------- | -------- |
| [Delegated_Administration](01-Basic/Delegated_Administration/) | A custom administration profile limited to one user group and one target group | |
| [API_Keys](01-Basic/API_Keys/) | An API key bound to a built-in profile and restricted to source addresses | API v3.12 |
| [Email_Notifications](01-Basic/Email_Notifications/) | SMTP relay of the Bastion and an email notification on system events | Bastion-wide |
| [Login_Banner](01-Basic/Login_Banner/) | Login banner and message of the day | Bastion-wide |
| [Web_Session_Manager](01-Basic/Web_Session_Manager/) | Host name and keys of the Web Session Manager | API v3.12, Bastion-wide |
| [Configuration_Options](01-Basic/Configuration_Options/) | Read and set options of a configuration file (wabengine banner) | API v3.12, REST API option `preview_resources` |
| [Encryption](01-Basic/Encryption/) | Import the encryption of a running Bastion and change its passphrase | Bastion-wide |

### Larger setups from an inventory

| Example | What it shows |
| ------- | ------------- |
| [Using_Inventory](02-Advanced/Using_Inventory/) | Users, servers and access rules described in YAML; three access models: [per user](02-Advanced/Using_Inventory/UseCase1%20-%20OneAuthorizationPerUser/), [per department](02-Advanced/Using_Inventory/UseCase2%20-%20OneAuthorizationPerDepartment/), [per account](02-Advanced/Using_Inventory/UseCase3%20-%20OneAuthorizationPerTargetService/) |

### How they were tested

Every example was applied, planned again (no change expected) and destroyed on a Bastion 12.4.3 (API v3.12) with provider 0.17.0 and Terraform 1.17.1, with these exceptions:

- EntraID_Authentication, X509_Authentication, Encryption and Configuration_Options were only planned: the Bastion checks the Entra ID app registration with Microsoft at creation, and the others change the listener certificate, the encryption or need `preview_resources`;
- Group_Mapping was tested on an OIDC authentication domain, since an Entra ID domain can't be created without a real tenant.

The objects are created on the Bastion; opening a real session needs real servers and credentials in place of the placeholders.

## Find the example for a resource

Every resource also has a data source of the same name, to read an object that already exists (see [Tags_and_Data_Sources](01-Basic/Tags_and_Data_Sources/)).

| Resource | Example |
| -------- | ------- |
| `user`, `usergroup`, `device`, `device_service` | [base](01-Basic/base/) |
| `domain`, `domain_account`, `domain_account_credential` | [base](01-Basic/base/), [Password_Rotation](01-Basic/Password_Rotation/), [SSH_Certificates](01-Basic/SSH_Certificates/) |
| `device_localdomain`, `device_localdomain_account`, `device_localdomain_account_credential` | [Approval_Workflow](01-Basic/Approval_Workflow/), [UseCase2](02-Advanced/Using_Inventory/UseCase2%20-%20OneAuthorizationPerDepartment/) |
| `targetgroup`, `authorization` | [base](01-Basic/base/), [Target_Login_Modes](01-Basic/Target_Login_Modes/), [Session_Restrictions](01-Basic/Session_Restrictions/) |
| `application` | [Web_Application](01-Basic/Web_Application/) (web), [UseCase1](02-Advanced/Using_Inventory/UseCase1%20-%20OneAuthorizationPerUser/) (program on a jump server), [Cluster](01-Basic/Cluster/) |
| `application_localdomain`, `application_localdomain_account`, `application_localdomain_account_credential` | [Application_Local_Account](01-Basic/Application_Local_Account/) |
| `cluster` | [Cluster](01-Basic/Cluster/) |
| `connection_policy` | [Connection_Policy](01-Basic/Connection_Policy/) |
| `checkout_policy`, `timeframe` | [Approval_Workflow](01-Basic/Approval_Workflow/) |
| `passwordchangepolicy` | [Password_Rotation](01-Basic/Password_Rotation/) |
| `certificate_authority` | [Certificate_Authority](01-Basic/Certificate_Authority/) |
| `externalauth_ldap`, `authdomain_ldap`, `authdomain_mapping` | [LDAP_Authentication](01-Basic/LDAP_Authentication/) |
| `authdomain_ad` | [AD_Authentication](01-Basic/AD_Authentication/) |
| `externalauth_oidc`, `authdomain_oidc` | [OIDC_Authentication](01-Basic/OIDC_Authentication/) |
| `externalauth_saml`, `authdomain_saml` | [SAML_Authentication](01-Basic/SAML_Authentication/) |
| `authdomain_azuread` | [EntraID_Authentication](01-Basic/EntraID_Authentication/) |
| `externalauth_kerberos` | [Kerberos_Authentication](01-Basic/Kerberos_Authentication/) |
| `externalauth_radius` | [RADIUS_MFA](01-Basic/RADIUS_MFA/) |
| `externalauth_tacacs` | [TACACS_Authentication](01-Basic/TACACS_Authentication/) |
| `config_x509`, `config_x509_crl`, `config_x509_ocsp` | [X509_Authentication](01-Basic/X509_Authentication/) |
| `profile` | [Delegated_Administration](01-Basic/Delegated_Administration/) |
| `apikey_v2` | [API_Keys](01-Basic/API_Keys/) (`apikey` is the deprecated first version) |
| `config_smtp`, `notification` | [Email_Notifications](01-Basic/Email_Notifications/) |
| `connection_message` | [Login_Banner](01-Basic/Login_Banner/) |
| `config_wsm` | [Web_Session_Manager](01-Basic/Web_Session_Manager/) |
| `configoption` | [Configuration_Options](01-Basic/Configuration_Options/) |
| `encryption` | [Encryption](01-Basic/Encryption/) |

All names take the `wallix-bastion_` prefix (`wallix-bastion_user`...).

## Before you start

You need:

- Terraform 1.5 or later (1.11 for OIDC_Authentication);
- HTTPS access from the machine running Terraform to the Bastion REST API;
- a Bastion user with the rights to create the objects of the example, and an API key for it (or its password).

Every example takes the same connection variables:

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `bastion_info_ip` | (required) | IP address or FQDN of the Bastion |
| `bastion_info_user` | `admin` | user that owns the API key |
| `bastion_info_token` | | API key; or set `bastion_info_password` |
| `bastion_info_api_version` | `v3.12` | `v3.8` for an older Bastion |
| `bastion_info_port` | `443` | HTTPS port |
| `bastion_info_insecure_skip_verify` | `false` | skip the TLS check (lab only) |

Put the non-secret values in `config.tfvars` (copied from `config.tfvars.example`) and pass the secrets as environment variables, so that they never land in a file:

```bash
export TF_VAR_bastion_info_token="<API key>"
terraform apply -var-file=config.tfvars
```

`*.tfvars` files are ignored by git in this repository; keep it that way in yours.

### TLS certificate

The provider checks the certificate of the Bastion (since provider 0.15.0). With a self-signed certificate, the plan fails with `x509: certificate signed by unknown authority`. The clean fix is a certificate issued by a CA that the machine running Terraform trusts (on Linux, `SSL_CERT_FILE` can point to an extra CA bundle). On a lab Bastion only, `bastion_info_insecure_skip_verify = true` skips the check.

### Terraform state

The state holds every value Terraform manages, passwords included (the OIDC client secret is the exception: it is write-only). Store it in a backend with access control and encryption at rest, not on a laptop or in git.

## Troubleshooting

| Error | Likely cause |
| ----- | ------------ |
| `x509: certificate signed by unknown authority` | Self-signed Bastion certificate, see [TLS certificate](#tls-certificate) |
| `api doesn't return OK: 401` | Wrong user, API key or password, or the API key isn't allowed from this source IP |
| `... not available with api version v3.8` | The resource needs API v3.12: set `bastion_info_api_version` and check the Bastion version |
| `<name> already exists` | The object exists on the Bastion but not in the state: rename it in the configuration, or bring it under Terraform with `terraform import` |
| `409 ... still associated` on destroy | The Bastion refuses to delete an object still used by another one; see the notes of the example (Web_Application, OIDC_Authentication) |

## Upgrading from older versions of these examples

The examples now target provider `~> 0.17.0`. If you used an earlier version of them:

- the provider checks TLS certificates since 0.15.0, see above;
- API versions v3.3 and v3.6 were removed in 0.14.0 (some examples still defaulted to v3.3);
- resource addresses changed in every example: a state created with the old code plans to destroy and recreate everything. Destroy with the old code first, or move the addresses with `moved` blocks.

## Maintaining the examples

The reference section of each README (between `BEGIN_TF_DOCS` and `END_TF_DOCS`) is generated by [terraform-docs](https://terraform-docs.io/) with `.terraform-docs.yml`; regenerate it after changing variables, outputs or resources:

```bash
cd 01-Basic/base && terraform-docs -c ../../.terraform-docs.yml .
```
