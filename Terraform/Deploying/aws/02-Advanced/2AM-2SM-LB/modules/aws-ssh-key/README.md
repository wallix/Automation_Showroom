<!-- markdownlint-disable MD033 -->
# AWS SSH KEY MODULE

Simple module that will generate a new ssh key pair and push it to AWS.

This is not a recommanded way to do in production as the private key will be stored as cleartext in the state file.

## Usage

```hcl
module "demo" {
  source    = "<path-to-module>"
  key_name  = "whatever name you would like to pass for the ssh key."
}
```

*The ouput can be use to create a local file.*

```hcl
resource "local_sensitive_file" "private_key" {
  content         = module.ssh_aws.ssh_private_key
  filename        = "private_key.pem"
  file_permission = "400"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_key_pair.key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [tls_private_key.key_pair](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of the ssh Keypair which will be created on AWS | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_pair_name"></a> [key\_pair\_name](#output\_key\_pair\_name) | Name of the ssh Keypair which was created on AWS. |
| <a name="output_ssh_private_key"></a> [ssh\_private\_key](#output\_ssh\_private\_key) | The SSH Private key in openssh format. |
| <a name="output_ssh_public_key"></a> [ssh\_public\_key](#output\_ssh\_public\_key) | The SSH public key in openssh format. |
<!-- END_TF_DOCS -->