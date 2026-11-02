# Configuration Options

The settings of the Bastion are options of configuration files: `wabengine` for the global configuration, `bastionadm` for the web UI, `rdpproxy` for the RDP proxy, and others. This example turns on the information banner of the global configuration (section `banner` of `wabengine`), for example to announce a maintenance, and reads the current values first with the data source.

Requires API v3.12 (Bastion 12.3.1 or later) and the REST API option `preview_resources` (configuration `wabrestapi`) enabled on the Bastion.

## What it creates

Nothing new: Terraform sets three options of an existing configuration.

```text
configuration "wabengine" (Bastion-wide)
  └── section banner: enable = true, type = info, message = "Scheduled maintenance..."

data source wallix-bastion_configoption: the banner options, read at plan time
```

## Run it

Prerequisites and the connection settings are described in the [Provisionning README](../../README.md#before-you-start).

```bash
cp config.tfvars.example config.tfvars           # set bastion_info_ip and the banner
export TF_VAR_bastion_info_token="<API key>"

terraform init
terraform plan -var-file=config.tfvars           # output banner_read_at_plan: the current values
terraform apply -var-file=config.tfvars
```

To remove the banner, set `banner_enabled = false` and apply again.

## Things to know

- **Destroy doesn't reset anything**: the API can't reset an option to its default, so `terraform destroy` leaves the last values applied. Keep the values read by the data source if you want to set them back.
- **Only the options in `values` are managed**; the other options of `wabengine` are neither changed nor compared. Use one resource per configuration file and set of options, or the resources overwrite each other.
- **Without `preview_resources`**, the apply fails with `403 Preview resources are not enabled in config`. The data source works without it. Tested with a plan only, on a Bastion 12.4.3 where the option is off.
- `values` is sensitive, in the resource and in the data source: the API returns some keys in clear (`backup_key` in `wabengine`, for example). The output uses `nonsensitive()` on the `banner` section only. List the options and their types with `GET /api/configoptions/wabengine?metainfo=true`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| wallix-bastion | ~> 0.17.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [wallix-bastion_configoption.banner](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/resources/configoption) | resource |
| [wallix-bastion_configoption.banner](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs/data-sources/configoption) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bastion\_info\_ip | IP address or FQDN of the Bastion. | `string` | n/a | yes |
| banner\_enabled | Show the banner in the web UI and the RDP and SSH selectors. | `bool` | `true` | no |
| banner\_message | Text of the banner, 255 characters at most. | `string` | `"Scheduled maintenance on Sunday from 02:00 to 04:00 UTC."` | no |
| banner\_type | Type of the banner (info by default on the Bastion). | `string` | `"info"` | no |
| bastion\_info\_api\_version | Version of the REST API. Changing configuration options requires v3.12. | `string` | `"v3.12"` | no |
| bastion\_info\_insecure\_skip\_verify | Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate. | `bool` | `false` | no |
| bastion\_info\_password | Password of bastion\_info\_user, when no API key is used. | `string` | `null` | no |
| bastion\_info\_port | HTTPS port of the Bastion REST API. | `number` | `443` | no |
| bastion\_info\_token | API key of bastion\_info\_user. Set this or bastion\_info\_password, preferably with TF\_VAR\_bastion\_info\_token. | `string` | `null` | no |
| bastion\_info\_user | Bastion user that owns the API key (or logs in with bastion\_info\_password). | `string` | `"admin"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| banner\_read\_at\_plan | Banner options read from the Bastion when the plan was made. |
<!-- END_TF_DOCS -->
