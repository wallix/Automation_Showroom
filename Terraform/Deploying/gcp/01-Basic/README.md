<!-- markdownlint-disable MD033 -->
# Deploy a single WALLIX Bastion or Access Manager on GCP

This example deploys one WALLIX Bastion or one WALLIX Access Manager on Google Cloud. It imports the WALLIX image archive from a Cloud Storage bucket as a Compute Engine image, creates a dedicated VPC network and subnetwork, a firewall rule restricted to `allowed_ip`, and an instance with an ephemeral public IP. cloud-init sets the `wabadmin`, `wabsuper` and `wabupgrade` passwords at first boot. `product_name` selects the product.

It is meant for labs and evaluations, not for production.

## Prerequisites

* Terraform 1.9 or later and the `gcloud` CLI.
* A GCP project with the Compute Engine API enabled, and an identity allowed to create images, disks, networks, firewall rules and instances in it (for example `roles/compute.admin`).
* Read access to the bucket holding the archive `<product_name>-<product_version>-gcp.tar.gz` (`gcp_bucket_name`). The examples use `wallix-cloud-images-gcp`; ask WALLIX support if your project cannot read it.
* SSH public keys for `root` and `wabadmin`.

Authenticate with Application Default Credentials:

```bash
gcloud auth application-default login
```

A service account key file also works (`gcp_credentials_file_path`), but avoid it when you can. If you use one, keep it outside the repository: Git here ignores `key.json` and `gcp_key.json`, not other JSON files.

## Deploy

```bash
cp bastion-10.4.0.tfvars.example bastion.tfvars      # or access-manager-4.4.0.tfvars.example
vi bastion.tfvars                                    # replace every <...> placeholder

terraform init
terraform plan  -var-file=bastion.tfvars
terraform apply -var-file=bastion.tfvars
```

### Inputs that matter

| Name | Why it matters |
| --- | --- |
| `product_name`, `product_version` | Select the archive to import. The version has four parts, e.g. `10.4.0.4`. |
| `allowed_ip` | Source ranges of the firewall rule. Use your own `/32`. |
| `gcp_project_name` | Target project ID. |
| `cidr_range` | Range of the new subnetwork. |
| `wabadmin_password`, `wabsuper_password`, `wabupgrade_password` | Service account passwords set by cloud-init. |

## Connect

`terraform output gcp_instance_ip` gives the public IP. From an address in `allowed_ip`:

* Web UI: `https://<ip>/` (self-signed certificate).
* SSH administration: `ssh -p 2242 wabadmin@<ip>`.

The firewall rule opens 22, 80, 443 and 2242 for both products, plus 3389 for the Bastion.

## Destroy

```bash
terraform destroy -var-file=bastion.tfvars
```

The imported image is deleted with the rest.

## Security notes

* The instance has a public IP; `allowed_ip` is the only filter in front of it. `0.0.0.0/0` exposes the web UI, SSH and the session proxies to the Internet.
* Passwords live in cleartext in your tfvars file and in the Terraform state.
* A root SSH key is injected through instance metadata.

## Reference

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | ~> 1.9 |
| cloudinit | ~> 2.3 |
| google | ~> 8.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [google_compute_disk.product_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_firewall.accessmanager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_image.product_image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_image) | resource |
| [google_compute_instance.product_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.product_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.product_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [cloudinit_config.conf](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allowed\_ip | CIDR blocks allowed to reach the instance. Use your own public IP as x.x.x.x/32; 0.0.0.0/0 exposes the instance to the whole Internet. | `list(string)` | n/a | yes |
| cidr\_range | CIDR range of the subnetwork created for the instance. | `string` | n/a | yes |
| gcp\_bucket\_name | Cloud Storage bucket holding the WALLIX image archive <product\_name>-<product\_version>-gcp.tar.gz. | `string` | n/a | yes |
| gcp\_project\_name | ID of the GCP project to deploy into. | `string` | n/a | yes |
| product\_name | WALLIX product to deploy: bastion or access-manager. | `string` | n/a | yes |
| product\_version | Full product version (x.y.z.q), as found in the image archive name <product\_name>-<product\_version>-gcp.tar.gz. | `string` | n/a | yes |
| ssh\_key\_root | SSH public key authorized for root, e.g. "ssh-ed25519 AAAA... user@host". | `string` | n/a | yes |
| ssh\_key\_wabadmin | SSH public key authorized for wabadmin, e.g. "ssh-ed25519 AAAA... user@host". | `string` | n/a | yes |
| wabadmin\_password | Password of the wabadmin account. | `string` | n/a | yes |
| wabsuper\_password | Password of the wabsuper account. | `string` | n/a | yes |
| wabupgrade\_password | Password of the wabupgrade account. | `string` | n/a | yes |
| gcp\_credentials\_file\_path | Path to a service account key file. Leave null to use Application Default Credentials (recommended). | `string` | `null` | no |
| gcp\_instance\_size | Machine type of the instance. | `string` | `"e2-small"` | no |
| gcp\_region | GCP region. | `string` | `"europe-west1"` | no |
| gcp\_region\_zone | GCP zone, inside gcp\_region. | `string` | `"europe-west1-b"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| gcp\_instance\_ip | Public IP of the instance. |
| gcp\_instance\_private\_ip | Private IP of the instance. |
<!-- END_TF_DOCS -->
