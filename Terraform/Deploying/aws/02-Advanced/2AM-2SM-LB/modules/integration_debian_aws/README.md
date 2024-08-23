# demo terraform module

//TODO: Complete the README

A terraform module to provide an integration jumphost in AWS.

## Module Input Variables

- `name` - variable name
- `environment` - variable environment

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

- `name` - does what it says on the tin
- `environment` - does what it says on the tin

## Authors

- Bryce SIMON
