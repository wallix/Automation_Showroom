# Alibaba deployments with Terraform

Deployments of the various resources, vms and automation alike can be done by using terraform and the alicloud provider.

## Alibaba Authentication

Terraform needs an authentication to Alibaba to create, manage and delete the resources.
Terraform has the possibility to authenticate using info passed in the alicloud provider's configuration. All informations needed are available in the `AccessKey Management` section of the user's profile in the Alibaba Cloud GUI.

Alibaba Cloud also has a [`CLI`](https://www.alibabacloud.com/help/en/alibaba-cloud-cli) which can be used to authenticate a user.

All ways to enter credentials for authentication are described [`here`](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs).

## Necessary information

Each terraform template requires specific information to identify both the resources to be created and the already existing resources to be used.
All the required information is given using terraform variables.\
While most of it is specific to the type of resource to be deployed, the name of the resource group on which to deploy them, the virtual private cloud and the virtual switch used, are mandatory for all of them.

## Windows and Linux vms

A generic vm, be it windows or linux, can be deployed using the images that are publicly available on Alicloud as base. This implies that the appropriate information to retrieve the right image must be provided.\
They are also deployed using the dedicated terraform resource `alicloud_instance`.

For Windows vms, as ssh is **not** enabled by default on the system, the only connection can be made on RDP 3389.

## Bastion and Access Manager

Bastion and Access Manager instances are created by importing the desiderated kvm-qcow2 image into an Object Storage Service bucket (OSS).
For those operations, we can use the [`ossutil`](https://www.alibabacloud.com/help/en/object-storage-service/latest/developer-tools-ossutil) binary to copy everything needed.

After importing all kvm-qcow2 images in the bucket, an ECS image needs to be created for each imported version using the [`Import Image`](https://www.alibabacloud.com/help/en/elastic-compute-service/latest/import-custom-images) functionnality.
The ECS images will be the entrypoints for ECS instances.
**For Bastion and Access Manager images be sure to select BIOS instead of UEFI !**

Starting a Bastion or an Access Manager instance by only using the ECS image as base delivers the vm as ready to be configured through the configuration screens. By using cloudinit to provide additional configuration, it is possible to bypass the configuration screens and have the system configure itself to deliver a ready-to-use instance.
