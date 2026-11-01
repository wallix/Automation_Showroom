# Terraform

Terraform examples for WALLIX products, in two groups:

| Folder | Purpose | Terraform providers |
| ------ | ------- | ------------------- |
| [Deploying](Deploying/) | Install a Bastion or an Access Manager on a cloud (AWS, Azure, GCP, Alibaba Cloud) | the cloud provider |
| [Provisionning](Provisionning/) | Configure a running Bastion: users, targets, accounts, authorizations, authentication | [`wallix/wallix-bastion`](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs) |

Within each group, the examples are sorted by level:

- **01-Basic**: one topic per example, ready to run once the connection settings are filled in. Start here to learn the provider.
- **02-Advanced**: closer to a real deployment; they assume you know Terraform (`for_each`, locals, state) and the infrastructure they target.

New to the Bastion provider? Read the [Provisionning README](Provisionning/README.md), then run [01-Basic/base](Provisionning/01-Basic/base/).

## Security

These are examples for labs and training, not production modules. Before reusing them:

- keep secrets (API keys, passwords) out of the code and of `*.tfvars` files committed to git; pass them as `TF_VAR_*` environment variables or from a secret manager;
- store the Terraform state in a protected backend: it holds the passwords Terraform manages;
- don't expose the Bastion or its targets on an open public IP (`0.0.0.0/0`), especially before the first configuration is done;
- keep TLS certificate verification on; skip it only on a lab Bastion with a self-signed certificate.
