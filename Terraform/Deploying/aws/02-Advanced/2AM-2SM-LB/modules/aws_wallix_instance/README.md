# Deployment module for session manager

//TODO: Complete the README

This module aim to provide a reusable way to deploy WALLIX aws image.

## Module Input Variables

- `instance_name` - Name of the instance. *Required*
- `project_name`  - Name of the project ( used for tagging and naming ). *Required*
- `subnet_id`     - ID of the subnet to use for this instance. *Required*
- `common_tags`   - Map of tags to apply on instances resources. *Default : None*
- `disk_size`     - size of the disk to use. *Default : 31*
- `aws_instance_size` - Instance size. Default: *t2.medium*

## Usage

```hcl
module "demo" {
  source = "github.com/my-repo/demo"

  name = "whatever variable you would like to pass"

  tags {
    "Environment" = "${var.environment}"
  }
}
```

## Outputs

- `key_pair_name` - does what it says on the tin
- `ssh_private_key` - does what it says on the tin

The ouput can be use to create a local file.

```hcl
resource "local_sensitive_file" "private_key" {
  content         = module.ssh_aws.ssh_private_key
  filename        = "private_key.pem"
  file_permission = "400"

}

## Authors

- Bryce SIMON
