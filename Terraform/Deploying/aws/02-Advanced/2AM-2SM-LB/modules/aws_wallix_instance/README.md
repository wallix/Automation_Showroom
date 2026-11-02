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
| ---- | ------- |
| terraform | >= 1.9.0 |
| aws | >= 6.0 |
| local | >=2.5.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_instance.wallix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.wallix](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_ami.wallix-ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ami\_from\_aws\_marketplace | Should we use the marketplace image ? If false, the shared image by WALLIX will be use. | `bool` | `true` | no |
| ami\_override | Force the usage of a specifique AMI-ID | `string` | `""` | no |
| aws\_instance\_size | Instance size to use. At least t3.xlarge recommended for production. | `string` | `"t2.medium"` | no |
| common\_tags | Map of tags to apply on instances resources. | `map(string)` | `{}` | no |
| disk\_size | Size of the root EBS volume, in GiB. Use at least 60 for production | `number` | `40` | no |
| disk\_type | EBS disk type | `string` | `"gp3"` | no |
| instance\_name | Name of the instance | `string` | n/a | yes |
| key\_pair\_name | Name of the key pair that will be use to connect to the instance. | `string` | n/a | yes |
| product\_name | Specifies the product to deploy: bastion / access-manager | `string` | `"bastion"` | no |
| product\_version | Specifies the version of the bastion or access-manager.  It can be empty, partial or full value (5, 4.0 , 4.4.1, 4.4.1.8). Empty value will look for the latest pushed image. | `string` | `""` | no |
| project\_name | Name of the project. Will be used for Naming and Tags. | `string` | n/a | yes |
| subnet\_id | ID of the subnet to use for this instance | `string` | n/a | yes |
| user\_data | Content as cloud-init, plain text rendered or Base64 | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| ami-info | Info regarding the AMI used. |
| instance | Full information of the instance. |
| instance-id | ID of the instance. |
| instance\_network\_interface\_id | ID of the network interface linked to the instance. |
| instance\_private\_ip | Private IP of the instance. |
<!-- END_TF_DOCS -->