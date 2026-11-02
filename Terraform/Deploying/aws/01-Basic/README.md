<!-- markdownlint-disable MD033 -->
# Deploy a single WALLIX Bastion or Access Manager on AWS

This example deploys one WALLIX Bastion or one WALLIX Access Manager instance in an existing VPC. It creates a dedicated subnet, a security group restricted to `allowed_ip`, and an EC2 instance with a public IP, using the AMI shared by WALLIX for the requested product and version. The same code handles both products; `product_name` selects which one.

It is meant for labs and evaluations, not for production.

## Prerequisites

* Terraform 1.9 or later and AWS credentials (see [../README.md](../README.md)).
* An existing VPC. The new subnet uses the VPC main route table, which must have a default route to an Internet Gateway, otherwise the public IP is not reachable.
* An existing EC2 key pair in the target region.
* Access to the WALLIX AMI. The code looks for an AMI named `<product_name>-<product_version>-aws` owned by account `519101999238`; ask WALLIX support to share it with your AWS account if `terraform plan` cannot find it.

## Deploy

```bash
cp bastion-10.0.3.tfvars.example bastion.tfvars        # or access-manager-4.4.0.tfvars.example
vi bastion.tfvars                                      # replace every <...> placeholder

terraform init
terraform plan  -var-file=bastion.tfvars
terraform apply -var-file=bastion.tfvars
```

`*.tfvars` files are ignored by Git in this repository.

### Inputs that matter

| Name | Why it matters |
| --- | --- |
| `product_name`, `product_version` | Select the AMI: its name must be exactly `<product_name>-<product_version>-aws`, e.g. `bastion-10.0.3.10-aws`. |
| `allowed_ip` | The only CIDRs allowed in the security group. Use your own `/32`. |
| `aws_vpc_id`, `subnet_cidr` | Existing VPC, and a free range inside it for the new subnet. |
| `aws_key_name` | Existing EC2 key pair attached to the instance. |

The full list is in the [Reference](#reference) section.

## Connect

Once the instance has booted, open `https://<aws_instance_ip>/` from an address listed in `allowed_ip`. The certificate is self-signed. The administration SSH service listens on port 2242. Which account receives the EC2 key pair, and the initial web credentials, depend on the WALLIX image version: check the WALLIX documentation for your version.

The security group opens the following ports to `allowed_ip`:

| Port | Purpose | Product |
| --- | --- | --- |
| 80, 443 | Web UI | both |
| 2242 | SSH administration | both |
| 22, 3389 | SSH and RDP session proxies | Bastion only |

## Destroy

```bash
terraform destroy -var-file=bastion.tfvars
```

## Security notes

* The instance has a public IP and accepts traffic from every CIDR in `allowed_ip`. Use your own `/32`; `0.0.0.0/0` exposes the web UI and the SSH administration port to the Internet.
* Egress is fully open.
* The root volume is encrypted with the account's default EBS key.

## Reference

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | ~> 1.9 |
| aws | ~> 6.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [aws_instance.product_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.accessmanager_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.labnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_ami.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| Project\_Name | Project name, used in resource names and in the Project\_Name tag. | `string` | n/a | yes |
| Project\_Owner | Value of the Project\_Owner tag (e.g. an e-mail address), useful for cost tracking. | `string` | n/a | yes |
| allowed\_ip | CIDR blocks allowed to reach the instance (HTTP/HTTPS, SSH admin on 2242, and SSH/RDP proxies for the Bastion). Use your own public IP as x.x.x.x/32; 0.0.0.0/0 exposes the instance to the whole Internet. | `list(string)` | n/a | yes |
| aws\_key\_name | Name of an existing EC2 key pair, used for SSH access to the instance. | `string` | n/a | yes |
| aws\_region | AWS region to deploy into. | `string` | n/a | yes |
| aws\_vpc\_id | ID of the existing VPC in which the subnet and the instance are created. | `string` | n/a | yes |
| product\_name | Product to deploy: bastion or access-manager. | `string` | n/a | yes |
| product\_version | Full product version, as found in the AMI name (<product\_name>-<product\_version>-aws). | `string` | n/a | yes |
| subnet\_cidr | CIDR of the subnet created for the instance. Must be a free range inside the VPC CIDR. | `string` | n/a | yes |
| aws\_instance\_size | EC2 instance type. | `string` | `"t3.medium"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| aws\_ami\_name | Name of the AMI used. |
| aws\_instance\_id | ID of the instance. |
| aws\_instance\_ip | Public IP of the instance. |
<!-- END_TF_DOCS -->
