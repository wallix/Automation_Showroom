# Deploy WALLIX access manager and Bastion

terraform init
terraform apply -var-file=<VAR_FILE>

example terraform apply -var-file=access-manager-4.3.0.3.tfvars

## AWS

Note that the usual and recommended way to authenticate to AWS when using Terraform is via the AWS CLI.

To do this, first, install the AWS CLI, then type aws configure.
You can then enter your access key ID, secret access key, and default region.
