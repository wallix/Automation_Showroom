# Base

This is a mix and match example. A bastion should already be on place and an API Key set.

Please copy config.tvfars.example to config.tvfars and change it to you needs.

run it with:

```bash
terraform init
terraform apply -var-file=config.tvfars

```

After testing you can remove change with:

```bash
terraform destroy -var-file=config.tvfars
```

# Advanced

Instructions for using inventory variables in Terraform

1.	Define Inventory Variables
All inventory variables are set in the file: data_input/inventory.yml

2. Ensure Proper Formatting
The inventory.yml file must follow a valid YAML structure.

3. Declare the Inventory File in the Root Module
In the root module’s main.tf, the inventory file is declared as a local variable using yamldecode.

4. Access the Variables
Use local.<key> to call the variables in your Terraform files.
