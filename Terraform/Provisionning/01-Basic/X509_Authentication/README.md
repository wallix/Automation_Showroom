# X509 Authentication

Lets users log in to the Bastion with a client certificate issued by their PKI instead of a password, with a revocation check by CRL and OCSP. X509 authentication is a global setting of the Bastion: it also sets the certificate of its web and API listener. Requires Terraform 1.5 or later.

## What it creates

```text
X509 configuration (global): listener certificate + CA of the user certificates, user authentication enabled
CRL check (global):          CRL downloaded by the Bastion from crl_url
OCSP check (global):         default responder ocsp_responder
local user "<prefix>-jdoe":  user_auths = ["local_x509"], certificate_dn = subject of its certificate
```

The user gets no authorization here: add it to a user group linked to target groups as in the [base](../base/) example.

## Run it

Apply it during a maintenance window: the Bastion restarts its web and API listener with the new certificate. The [connection settings](../../README.md#before-you-start) are shared by all the examples.

```bash
cp config.tfvars.example config.tfvars           # set the Bastion, certificate files, CRL and OCSP URLs, user DN
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform plan -var-file=config.tfvars           # check the certificate and the global settings before applying
terraform apply -var-file=config.tfvars
```

Clean up with `terraform destroy -var-file=config.tfvars`.

## Things to know

- **`config_x509` changes the certificate of the web and API listener**, and requires it (`server_public_key`, `server_private_key`) even to only enable user certificates. Destroying it resets the X509 configuration of the Bastion (`DELETE /api/config/x509`). The private key is kept in the Terraform state (sensitive).
- **A user authenticates with its certificate when `local_x509` is in its `user_auths`**: the API refuses `certificate_dn` without it (`Field certificate_dn is forbidden without userauth local_x509`).
- **CRL and OCSP are singletons that destroy doesn't reset**: set `crl_check` and `ocsp_check` to `false` and apply before removing them.
- **The Bastion downloads the CRL from `crl_url` during the apply**, and the apply fails when the Bastion can't reach it (provider documentation).

This example was only planned on the test Bastion (the listener certificate is shared). The user and the OCSP settings were applied and destroyed separately; `crl_check` was applied without a CRL source.

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
| [wallix-bastion_config_x509.main](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/config_x509) | resource |
| [wallix-bastion_config_x509_crl.main](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/config_x509_crl) | resource |
| [wallix-bastion_config_x509_ocsp.main](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/config_x509_ocsp) | resource |
| [wallix-bastion_user.cert](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| bastion\_certificate\_file | PEM certificate of the Bastion web and API listener (replaces the current one). | `string` | `"bastion.crt"` | no |
| bastion\_info\_api\_version | Version of the REST API: v3.12, or v3.8 for an older Bastion. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |
| bastion\_private\_key\_file | PEM private key of that certificate. | `string` | `"bastion.key"` | no |
| crl\_url | URL the Bastion downloads the CRL of the users CA from. It must be reachable from the Bastion. | `string` | `"http://pki.example.com/users-ca.crl"` | no |
| ocsp\_responder | OCSP responder of the users CA. | `string` | `"http://ocsp.example.com"` | no |
| user\_certificate\_dn | Subject DN of the certificate of the Bastion user. | `string` | `"CN=jdoe,OU=Users,O=Example,C=FR"` | no |
| users\_ca\_file | PEM certificate of the CA that issues the user certificates. | `string` | `"users-ca.pem"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| user\_name | Bastion user that authenticates with its certificate. |
<!-- END_TF_DOCS -->
