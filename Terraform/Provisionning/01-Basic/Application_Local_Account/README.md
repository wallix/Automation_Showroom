# Application Local Account

An account that only exists inside one application (the built-in admin of a web console, for instance) belongs in a local domain of that application rather than in a global domain. The local domain is part of the application (the API returns it in the `local_domains` of the application) and its accounts can only be used with it. Requires a Bastion with API v3.12 for the web application.

For an account shared by several applications or servers, use a global domain as in [Web_Application](../Web_Application/).

## What it creates

```text
web application "<prefix>" (https://intranet.example.com, policy WEBAPP)
  └── local domain "local"
         └── account "app-admin" ── credential: password in the vault (TF_VAR_app_account_password)

target group "<prefix>"
  └── session account: app-admin@local@<prefix> (domain_type "local", application "<prefix>")
```

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, the URL, the account login
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_app_account_password="<password of the application account>"

terraform init
terraform apply -var-file=config.tfvars
```

Authorize a user group on the target group (`subprotocols = ["WEBAPP"]`) as in [Web_Application](../Web_Application/) to open sessions. Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **The password goes either on the account or in a credential, not both.** `wallix-bastion_application_localdomain_account` has a `password` argument; the credential resource can't be created for an account that already has one. Only the `password` type exists for application accounts.
- **In a target group, a local domain account is `domain_type = "local"`** with the `application` that owns the domain (a device local account names its `device` and `service` instead).
- **The password is in the Terraform state** (as a sensitive value). Treat the state as a secret, or manage the password outside Terraform.

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
| [wallix-bastion_application.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application) | resource |
| [wallix-bastion_application_localdomain.local](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application_localdomain) | resource |
| [wallix-bastion_application_localdomain_account.admin](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application_localdomain_account) | resource |
| [wallix-bastion_application_localdomain_account_credential.admin](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application_localdomain_account_credential) | resource |
| [wallix-bastion_targetgroup.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| app\_account\_password | Password of that account, stored in the Bastion vault. Pass it with TF\_VAR\_app\_account\_password. | `string` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| app\_account\_login | Login of the account that only exists in the web application. | `string` | `"app-admin"` | no |
| application\_url | URL the user's browser session opens. | `string` | `"https://intranet.example.com"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| application | Web application created on the Bastion. |
| target | Target of the target group (account@local domain@application). |
<!-- END_TF_DOCS -->
