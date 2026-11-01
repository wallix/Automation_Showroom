# Base

The smallest end-to-end configuration: one Bastion user can open an SSH session on one server, through the Bastion, with the session recorded. Start here if you have never used the provider.

## What it creates

```text
user ──member of──> user group ──┐
                                 ├── authorization (SSH subprotocols, recorded)
target group ──session account──┘
     └── account "admin" (global domain, password in the vault)
            └── used on device "<prefix>-srv01", service SSH (port 22)
```

Every object name starts with a random prefix (`demo-<adjective>-<animal>`), so the example can run several times on a shared Bastion. The user also gets an SSH key pair: the public key is set on the Bastion user and the private key is written next to the code (`<prefix>.pem`).

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # then set bastion_info_ip
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform apply -var-file=config.tfvars

terraform output -raw user_password              # password of the new Bastion user
```

Log in to the Bastion with the new user: the target from `terraform output target` is listed in its authorized targets. The SSH server itself is a placeholder (`192.0.2.10`); set `target_host` and the real password of the account to open a working session.

Clean up with:

```bash
terraform destroy -var-file=config.tfvars
```

## Things to know

- The user password and the account password are random and kept in the Terraform state. Treat the state as a secret.
- `allthetime`, `user` and `SSH` are objects that exist on every Bastion (timeframe, profile and connection policy): the example uses them without creating them.
- A subprotocol (`SSH_SCP_UP`, `SFTP_SESSION`...) has to be enabled on the service and on the authorization to be usable.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| local | ~> 2.9 |
| random | ~> 3.9 |
| tls | ~> 4.4 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [local_sensitive_file.user_private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [random_password.target_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.demo](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [tls_private_key.user](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [wallix-bastion_authorization.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/authorization) | resource |
| [wallix-bastion_device.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device) | resource |
| [wallix-bastion_device_service.ssh](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/device_service) | resource |
| [wallix-bastion_domain.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain) | resource |
| [wallix-bastion_domain_account.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account) | resource |
| [wallix-bastion_domain_account_credential.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/domain_account_credential) | resource |
| [wallix-bastion_targetgroup.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/targetgroup) | resource |
| [wallix-bastion_user.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |
| [wallix-bastion_usergroup.demo](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/usergroup) | resource |
| [wallix-bastion_version.current](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| target\_account\_login | Login of the account used on the SSH server. | `string` | `"admin"` | no |
| target\_host | IP address or FQDN of the SSH server to reach through the Bastion. | `string` | `"192.0.2.10"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bastion\_version | Version of the Bastion the example ran against. |
| target | Target the user is authorized on. |
| user\_name | Bastion user created by the example. |
| user\_password | Password of the Bastion user (terraform output -raw user\_password). |
| user\_private\_key\_file | Private SSH key of the Bastion user. |
<!-- END_TF_DOCS -->
