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
