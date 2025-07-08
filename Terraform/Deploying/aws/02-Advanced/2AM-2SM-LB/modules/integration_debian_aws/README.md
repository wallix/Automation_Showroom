<!-- markdownlint-disable MD033 -->
# demo terraform module

A terraform module to provide an integration jumphost for WALLIX integrators for resources in AWS environment.
This idea is to provide a secure way to provide access to Wallix target for third party without providing them any access to AWS Tenant.

## Usage example

```hcl
module "integration_debian" {
  count             = var.deploy-integration-debian ? 1 : 0
  source            = "./modules/integration_debian_aws"
  tags              = local.common_tags
  sm-instances      = local.sm_instances
  project_name      = local.project_name
  am-instances      = local.am_instances
  allowed_ips       = var.allowed_ips
  subnet_id         = try(aws_subnet.subnet_az_AM[0].id, aws_subnet.subnet_az_SM[0].id) // if no am are created, will use the first bastion subnets
  aws_instance_size = var.aws_instance_size_debian
  common_tags       = local.common_tags
  vpc_id            = aws_vpc.cluster.id
  key_pair_name     = module.ssh_aws.key_pair_name
  private_key       = module.ssh_aws.ssh_private_key

}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.85.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >=2.3.5 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >=2.5.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.85.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | >=2.3.5 |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.6.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.public_ip_debian](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_instance.debian_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.debian-linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.debian_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.password_rdpuser](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.debian-linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [cloudinit_config.integration_debian](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | Specifies the ips/networks allowed to access integration instance. e.g: [''10.0.0.0/16'',''90.15.25.21/32''] | `list(string)` | <pre>[<br/>  "127.0.0.1/32"<br/>]</pre> | no |
| <a name="input_am-instances"></a> [am-instances](#input\_am-instances) | list of AM IP or Network in CIDR Format. | `list(string)` | n/a | yes |
| <a name="input_aws_instance_size"></a> [aws\_instance\_size](#input\_aws\_instance\_size) | Specifies the instance sizing. | `string` | `"t3.medium"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of tags to apply on instances resources. | `map(string)` | `{}` | no |
| <a name="input_debian_version"></a> [debian\_version](#input\_debian\_version) | version debian to use. 11, 12. | `number` | `12` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Name of the key pair that will be use to connect to the instance. | `string` | n/a | yes |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | Private key to be added in /home/admin/.ssh/ to connect to WALLIX Instances. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project. Will be used for Naming and Tags. | `string` | n/a | yes |
| <a name="input_public_ssh_key"></a> [public\_ssh\_key](#input\_public\_ssh\_key) | Public key to be added in /home/rdpuser/.ssh/authorized\_keys. | `string` | n/a | yes |
| <a name="input_sm-instances"></a> [sm-instances](#input\_sm-instances) | list of SM IP or Network in CIDR Format. | `list(string)` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet to use for this instance | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply on instances resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | vpc\_id to which attach the security group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudinit_config"></a> [cloudinit\_config](#output\_cloudinit\_config) | Content of the cloud init. Mostly for debug |
| <a name="output_password_rdpuser"></a> [password\_rdpuser](#output\_password\_rdpuser) | Generated password for rdp connexion with rdpuser. |
| <a name="output_private_ip_debian_admin"></a> [private\_ip\_debian\_admin](#output\_private\_ip\_debian\_admin) | Private IP of the debian instance. |
| <a name="output_public_ip_debian_admin"></a> [public\_ip\_debian\_admin](#output\_public\_ip\_debian\_admin) | Public IP of the debian instance. |
| <a name="output_z_connect"></a> [z\_connect](#output\_z\_connect) | How to connect to instance. |
<!-- END_TF_DOCS -->