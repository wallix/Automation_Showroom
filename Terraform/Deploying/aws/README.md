# AWS deployments with Terraform

Deployments of the various resources, vms, networks and automation alike can be done by using terraform and the aws provider.

We highly recommend to follow the official tutorial before jumping on the usage with WALLIX products.

[Follow the tutorial rabbit](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)

## AWS Authentication

Terraform needs an authentication to AWS to create, manage and delete the resources. Various methods of authentication exist, as described in the [documentation of the aws provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

When authenticated through the CLI, Terraform will use those credentials to authenticate against AWS as long as they are valid and present on the system, meaning that there is no need to refresh them between two deployments if those are done back-to-back.

## Necessary information

Each terraform template requires specific information to identify both the resources to be created and the already existing resources to be used.
All the required information is given using terraform variables.

While most of it is specific to the type of resource to be deployed, the name of the resource group on which to deploy them is mandatory for all of them.
