# Deploy WALLIX on Alibaba Cloud with Terraform

| Example | What it deploys |
| --- | --- |
| [01-Basic/bastion](01-Basic/bastion/) | One WALLIX Bastion ECS instance from a custom image, in an existing VPC |
| [01-Basic/access-manager](01-Basic/access-manager/) | One WALLIX Access Manager ECS instance from a custom image, in an existing VPC |

## Authentication

The examples use the `aliyun/alicloud` provider. Prefer environment variables over writing keys in a tfvars file:

```bash
export ALICLOUD_ACCESS_KEY=<access-key-id>
export ALICLOUD_SECRET_KEY=<access-key-secret>
```

The [Alibaba Cloud CLI](https://www.alibabacloud.com/help/en/alibaba-cloud-cli) profiles (`ALICLOUD_PROFILE`) and the other methods listed in the [provider documentation](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs) work too. An AccessKey pair is created from the AccessKey Management page of the user profile in the console.

## Preparing the WALLIX images

Bastion and Access Manager are delivered as KVM qcow2 images. Before running the examples:

1. Upload the qcow2 file to an Object Storage Service (OSS) bucket, for example with [ossutil](https://www.alibabacloud.com/help/en/object-storage-service/latest/developer-tools-ossutil).
2. Create an ECS custom image from it with [Import Image](https://www.alibabacloud.com/help/en/elastic-compute-service/latest/import-custom-images). Select **BIOS** as boot mode, not UEFI.
3. Name the image so that it starts with `bastion-<version>` or `access-manager-<version>`: the examples look it up with that prefix among your own images.

Booting the image alone stops on the appliance configuration screens. The examples pass a cloud-init configuration that sets the service account passwords and SSH keys, so the instance comes up ready to use.
