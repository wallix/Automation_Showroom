<!-- markdownlint-disable MD033 -->
# Deploy a WALLIX Bastion on Alibaba Cloud

This example creates one ECS instance from your WALLIX Bastion custom image, in an existing VPC and vSwitch, with a public IP. cloud-init sets the host name, the `wabadmin`, `wabsuper` and `wabupgrade` password hashes, and your SSH key for `wabadmin` and `root`. Terraform then connects as `root` on port 2242 to add the public IP to `http_host_trusted_hostnames` and to sync the clock.

It is meant for labs and evaluations, not for production.

## Prerequisites

* Terraform 1.9 or later and Alibaba Cloud credentials (see [../../README.md](../../README.md)).
* A custom image whose name starts with `bastion-<bastion_version>` (see [Preparing the WALLIX images](../../README.md#preparing-the-wallix-images)).
* An existing resource group, VPC and vSwitch. The instance uses the **first security group found in the VPC**: make sure it allows TCP 2242 from the machine running Terraform, and the ports you need (443, 22, 3389) from your own IP only.
* An SSH key pair, and SHA-512 hashes of the three passwords:

  ```bash
  mkpasswd --method=SHA-512
  ```

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars          # replace every <...> placeholder

terraform init
terraform apply
```

### Inputs that matter

| Name | Why it matters |
| --- | --- |
| `bastion_version` | Prefix used to find the custom image. |
| `vpc`, `vswitch`, `resource_group` | Existing network and resource group. |
| `internet_max_bandwidth_out` | Must stay above 0: it allocates the public IP that the provisioning step connects to. |
| `bastion_cpu`, `bastion_memory`, `bastion_instance_type` | Used to pick the first matching instance type in the region. |
| `wabadmin_password`, `wabsuper_password`, `wabupgrade_password` | SHA-512 crypt hashes, not cleartext. |
| `ssh_key`, `private_key_file` | Public key installed by cloud-init, private key used by Terraform to connect. |

## Connect

`terraform output bastion_public_ip` gives the address:

* Web UI: `https://<ip>/` (self-signed certificate).
* SSH administration: `ssh -p 2242 wabadmin@<ip>`.

## Destroy

```bash
terraform destroy
```

## Security notes

* The instance has a public IP; the security group you already have is the only filter. Check its rules before applying.
* Password SSH login is enabled (`ssh_pwauth: true`) and `root` accepts your SSH key.
* The tfvars file holds password hashes and possibly AccessKeys: it is ignored by Git in this repository, keep it that way.

## Reference

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | ~> 1.9 |
| alicloud | ~> 2.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [alicloud_instance.bastion](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/instance) | resource |
| [alicloud_images.bastion_image](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/images) | data source |
| [alicloud_instance_types.bastion_compute](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/instance_types) | data source |
| [alicloud_security_groups.default](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/security_groups) | data source |
| [alicloud_vpcs.default](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/vpcs) | data source |
| [alicloud_vswitches.default](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/data-sources/vswitches) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| private\_key\_file | Path to the private key matching ssh\_key, used by Terraform to run the post-install commands as root on port 2242. | `string` | n/a | yes |
| region | Alibaba Cloud region ID, e.g. eu-central-1. | `string` | n/a | yes |
| resource\_group | ID of the existing resource group in which the instance is created. | `string` | n/a | yes |
| ssh\_key | SSH public key authorized for wabadmin and root. | `string` | n/a | yes |
| vpc | Name of the existing VPC. The instance uses the first security group found in it. | `string` | n/a | yes |
| vswitch | Name of the existing vSwitch (subnet) to attach the instance to. | `string` | n/a | yes |
| wabadmin\_password | SHA-512 crypt hash of the wabadmin password. | `string` | n/a | yes |
| wabsuper\_password | SHA-512 crypt hash of the wabsuper password. | `string` | n/a | yes |
| wabupgrade\_password | SHA-512 crypt hash of the wabupgrade password. | `string` | n/a | yes |
| access\_key | Alibaba Cloud AccessKey ID. If null, the provider reads ALICLOUD\_ACCESS\_KEY (or ALICLOUD\_PROFILE). | `string` | `null` | no |
| bastion\_cpu | vCPU count used to select the instance type. | `number` | `2` | no |
| bastion\_instance\_type | Instance type family used to select the instance type. | `string` | `"ecs.g7"` | no |
| bastion\_memory | Memory (GiB) used to select the instance type. | `number` | `8` | no |
| bastion\_private\_ip | Fixed private IP inside the vSwitch. Null lets Alibaba Cloud pick one. | `string` | `null` | no |
| bastion\_version | Bastion version; the custom image name must start with bastion-<version>. | `string` | `"10.0.2.9"` | no |
| internet\_charge\_type | Public bandwidth billing: PayByTraffic or PayByBandwidth. | `string` | `"PayByTraffic"` | no |
| internet\_max\_bandwidth\_out | Outbound public bandwidth in Mbit/s. A value above 0 allocates a public IP, which the provisioning step needs. | `number` | `100` | no |
| secret\_key | Alibaba Cloud AccessKey secret. If null, the provider reads ALICLOUD\_SECRET\_KEY (or ALICLOUD\_PROFILE). | `string` | `null` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| bastion\_public\_ip | Public IP of the instance. |
<!-- END_TF_DOCS -->
