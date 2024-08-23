# AWS SSH KEY MODULE

Simple module that will generate a new ssh key pair and push it to AWS.

This is not a recommanded way to do in production as the private key will be stored as cleartext in the state file.

## Module Input Variables

- `key_name` - variable name

## Usage

```hcl
module "demo" {
  source = "<path-to-module>"
  key_name = "whatever name you would like to pass for the ssh key."

}
```

## Outputs

- `key_pair_name`   - return the name of the ssh key created on aws.
- `ssh_private_key` - return the private key in an openssh format.
- `ssh_public_key`  - return the public key in an openssh format.

*The ouput can be use to create a local file.*

```hcl
resource "local_sensitive_file" "private_key" {
  content         = module.ssh_aws.ssh_private_key
  filename        = "private_key.pem"
  file_permission = "400"

}
```

## Authors

- Bryce SIMON
