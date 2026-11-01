# Web Application

Publishes a web application through the Bastion: users open it in a browser session started by the Bastion, which records the session and can log them in with an account they never see. This uses the `web_application` category and the built-in `WEBAPP` connection policy, which need a Bastion with API v3.12. No jump server or RDS host is involved.

For a thick client launched on a Windows jump server (the `standard` category), see the applications of [UseCase1](../../02-Advanced/Using_Inventory/UseCase1%20-%20OneAuthorizationPerUser/).

## What it creates

```text
user group "<app>_users" ──┐
                           ├── authorization "<app>" (subprotocol WEBAPP, recorded)
target group "<app>" ──────┘
     └── session account: account "svc-intranet" (global domain "webapps", password in the vault)
            └── used on application "<app>" (https://intranet.example.com, policy WEBAPP)
```

The account is a global domain account attached to the application by the target group: the session account names an `application` instead of a `device` and a `service`.

## Run it

The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, the URLs, the account login, the users
export TF_VAR_bastion_info_token="<API key>"
export TF_VAR_webapp_account_password="<password of the account>"

terraform init
terraform apply -var-file=config.tfvars
```

The users listed in `users` must already exist on the Bastion. Clean up with `terraform destroy -var-file=config.tfvars`.

## Automatic login

With `login_form_url` and `login_button_selector`, the Bastion fills the login form of the application with the account and submits it. The selector identifies the submit button, as in the web UI field "Login button identifier" (`#submit-button`, `button[type=submit]`...). Leave both unset to let the user type the credentials. `allow_non_post_form` (not used here) allows the injection into a form that isn't submitted with a POST.

## Things to know

- **The account password is in the Terraform state** (as a sensitive value). Treat the state as a secret, or manage the password outside Terraform.
- **The account depends on the application** (`depends_on` in `application.tf`), only to set the destroy order: the Bastion refuses to delete an application while an account is attached to it, so the account goes first.
- **Use a copy to change the policy.** The built-in `WEBAPP` policy can't be deleted; to change its options, create your own policy from the built-in one with `wallix-bastion_connection_policy` and its data source, as shown in the provider documentation, and set it as `connection_policy`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_application.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/application) | resource |
| [wallix-bastion_authorization.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_domain.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_targetgroup.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_usergroup.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_connection_policy.webapp](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/connection_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| application\_url | URL the user's browser session opens. | `string` | n/a | yes |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| webapp\_account\_login | Login of the account injected into the web application. | `string` | n/a | yes |
| webapp\_account\_password | Password of that account, stored in the Bastion vault (and in the Terraform state, as a sensitive value). | `string` | n/a | yes |
| application\_name | Name of the web application on the Bastion (also used for its target group and authorization). | `string` | `"intranet"` | no |
| bastion\_info\_api\_version | Version of the REST API. Web applications require v3.12. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| domain\_name | Global domain holding the account of the web application. | `string` | `"webapps"` | no |
| login\_button\_selector | CSS selector of the login button, e.g. #submit-button. Set it with login\_form\_url. | `string` | `null` | no |
| login\_form\_url | URL of the login page, for the automatic login. null: no automatic login. | `string` | `null` | no |
| users | Existing Bastion users allowed to open the web application. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| application | Web application created on the Bastion. |
| target | Target the user group is authorized on (account@domain@application). |
<!-- END_TF_DOCS -->
