# Deploy WALLIX on AWS with Terraform

| Example | What it deploys |
| --- | --- |
| [01-Basic](01-Basic/) | One Bastion or one Access Manager instance in an existing VPC, with a public IP |
| [02-Advanced/2AM-2SM-LB](02-Advanced/2AM-2SM-LB/) | A new VPC with two Access Managers behind an ALB, two Bastions (Session Managers) behind an NLB, and an optional Debian jump host |

If you are new to Terraform on AWS, the [HashiCorp AWS tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started) covers the basics used here.

## Authentication

Terraform uses the standard AWS credential chain: environment variables, the shared credentials file written by `aws configure` or `aws sso login`, or an instance role. The [AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) lists every method. Check which identity and account Terraform will use before applying:

```bash
aws sts get-caller-identity
```

## Inputs

Each example takes its inputs from Terraform variables. Copy the `*.tfvars.example` file of the example, fill in the placeholders, and pass it with `-var-file` (or name it `*.auto.tfvars` so Terraform loads it automatically). `*.tfvars` files are ignored by Git in this repository because they usually hold environment-specific or sensitive values.
