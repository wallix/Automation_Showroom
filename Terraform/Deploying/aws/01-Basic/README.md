# Deploy WALLIX Access Manager and Bastion on AWS

## Requirements

* A VPC should already exist.
* A PAIR KEY was already created.
* AMI were shared by WALLIX Support

Adapt samples to your needs

```bash
cp bastion-10.0.3.tfvars.example bastion-10.0.3.tfvars
vi bastion-10.0.3.tfvars
```

## Deploy

```bash
terraform init      # initializes the working directory 
terraform fmt       # format files
terraform validate  # validates the configuration files 

terraform apply -var-file=<VAR_FILE>
```

example: terraform apply -var-file=access-manager-4.3.0.3.tfvars
