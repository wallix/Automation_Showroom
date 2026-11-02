<!-- markdownlint-disable MD033 -->
# CLOUD-INIT MODULE

Simple module to generate WALLIX cloud init data to be use with WALLIX Access Manager or Session Manager.

## Usage

```hcl
module "cloudinit-demo" {
  source    = "<path-to-module>"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9.0 |
| cloudinit | >=2.3.5 |
| local | >=2.5.2 |
| random | >=3.6.3 |

## Resources

| Name | Type |
| ---- | ---- |
| [random_password.cryptokey_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.webui_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cloudinit_config.wallix_appliance](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| http\_host\_trusted\_hostnames | fqdn of the loadbalancers which will be added to http\_host\_trusted\_hostnames.  If muliple values, should be separated by a comma. | `string` | `""` | no |
| install\_replication | !!! Session Manager Only !!!  Should we install replication ? | `bool` | `false` | no |
| set\_service\_user\_password | Should we changepasswd for WALLIX Service user ?  ( Wabadmin, Wabsuper, Wabupgrade) | `bool` | `false` | no |
| set\_webui\_password\_and\_crypto | !!! Session Manager Only !!! Should we change password for WebUI Admin and set encryption key? | `bool` | `false` | no |
| to\_base64\_encode | Should the user-data be encoded in base64? | `bool` | `false` | no |
| to\_gzip | Should the user-data be compressed ? | `bool` | `false` | no |
| use\_of\_lb | Are you going to use a loadbalancer ? | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudinit\_config | The rendered user-data / cloud-init data |
| wallix\_crypto | Cryptokey |
| wallix\_password\_wabadmin | Wabadmin password |
| wallix\_password\_wabsuper | Wabsuper password |
| wallix\_password\_wabupgrade | Wabupgrade password |
| wallix\_password\_webui | Webui Admin password |
<!-- END_TF_DOCS -->