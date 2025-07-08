<!-- markdownlint-disable MD033 -->
# Deployment module for Session Manager and Access Manager

This module aim to provide a reusable way to deploy WALLIX aws image.

The ouput can be used to create a local file.

## Usage

This minimal usage will deploy a Session manager in the default vpc using the latest image available on the Marketplace.

```hcl
module "instance_access_manager" {
  source         =  "<path-to-module>"
  instance_name  =  "<name of the instance>"
  key_pair_name  =  "<name of AWS Key pair to use>"
  project_name   =  "<name of the project>"
  subnet_id      =  "<subnet id to use>"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.85.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >=2.5.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.85.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.wallix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.wallix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_ami.wallix-ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_from_aws_marketplace"></a> [ami\_from\_aws\_marketplace](#input\_ami\_from\_aws\_marketplace) | Should we use the marketplace image ? If false, the shared image by WALLIX will be use. | `bool` | `true` | no |
| <a name="input_ami_override"></a> [ami\_override](#input\_ami\_override) | Force the usage of a specifique AMI-ID | `string` | `""` | no |
| <a name="input_aws_instance_size"></a> [aws\_instance\_size](#input\_aws\_instance\_size) | Instance size to use. At least t3.xlarge recommended for production. | `string` | `"t2.medium"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of tags to apply on instances resources. | `map(string)` | `{}` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Size of the EBS block for /dev/sda1. Use at least 60 for production | `number` | `40` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | EBS disk type | `string` | `"gp3"` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the instance | `string` | n/a | yes |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Name of the key pair that will be use to connect to the instance. | `string` | n/a | yes |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | Specifies the product to deploy: bastion / access-manager | `string` | `"bastion"` | no |
| <a name="input_product_version"></a> [product\_version](#input\_product\_version) | Specifies the version of the bastion or access-manager.<br/> It can be empty, partial or full value (5, 4.0 , 4.4.1, 4.4.1.8). Empty value will look for the latest pushed image. | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project. Will be used for Naming and Tags. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet to use for this instance | `string` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Content as cloud-init, plain text rendered or Base64 | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami-info"></a> [ami-info](#output\_ami-info) | Info regarding the AMI used. |
| <a name="output_instance"></a> [instance](#output\_instance) | Full information of the instance. |
| <a name="output_instance-id"></a> [instance-id](#output\_instance-id) | ID of the instance. |
| <a name="output_instance_network_interface_id"></a> [instance\_network\_interface\_id](#output\_instance\_network\_interface\_id) | ID of the network interface linked to the instance. |
| <a name="output_instance_private_ip"></a> [instance\_private\_ip](#output\_instance\_private\_ip) | Private IP of the instance. |
<!-- END_TF_DOCS -->