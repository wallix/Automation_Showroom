<!-- markdownlint-disable MD033 -->
# Deploy WALLIX Access Manager and Session Manager (Bastion) clusters with loadbalancer on AWS

## Introduction

This is an example of AWS deployment with cluster setup.
It contains mutiples modules to help understands the steps of creation.
Those modules can be use as standalone, therefore contains their own README ( look at them to find extra tweaks & tricks you can do :p. )

This example is intended to present good practices but keeping the ease of use in mind, so fine for lab. If you intend to use it in production please adapt it.

![Architecture](AWS_2AM-2SM-LB.drawio.png)

## Table of Content

- [Deploy WALLIX Access Manager and Session Manager (Bastion) clusters with loadbalancer on AWS](#deploy-wallix-access-manager-and-session-manager-bastion-clusters-with-loadbalancer-on-aws)
  - [Introduction](#introduction)
  - [Table of Content](#table-of-content)
  - [What to check before starting ?](#what-to-check-before-starting-)
  - [Deploy](#deploy)
  - [Configure](#configure)
  - [Replication](#replication)
  - [Cost](#cost)
  - [Known issues](#known-issues)
    - [Debian Terms and Conditions not accepted](#debian-terms-and-conditions-not-accepted)
    - [Failing to import certificate on loadbalancer](#failing-to-import-certificate-on-loadbalancer)
    - [I can't access the Debian Machine from my IP](#i-cant-access-the-debian-machine-from-my-ip)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

## What to check before starting ?

- Access and Right to AWS
- AMI were shared by WALLIX Support if the versions you want to test are not available on MarketPlace.
- terraform is installed

Adapt samples to your needs, ( Make sure to change the allowed-ips)

```shell
cp lab.auto.tfvars.example lab.auto.tfvars
vi lab.auto.tfvars
```

## Deploy

```shell
terraform init              # initializes the working directory
terraform fmt --recursive   # format files
terraform validate          # validates the configuration files
terraform apply             # apply configuration
```

Some outputs are marked as sensible. Example: `sm_password_wabadmin = <sensitive>`

Use `terraform output <name of the output>` to show them. Example :`terraform output sm_password_wabadmin`

Key outputs include:

- **am_url_alb**: URL to access the Access Manager cluster via Application Load Balancer.
- **sm_fqdn_nlb**: FQDN to access the Session Manager cluster via Network Load Balancer.
- **debian_connect**: SSH/RDP connection details for the integration Debian instance.
- **am_password_wabadmin**, **sm_password_wabadmin**: Sensitive admin passwords for Access Manager and Session Manager.
- **ssh_private_key**: Generated SSH private key for instance access.
- **all_ips**, **all_secrets**: Lists of IPs and secrets generated during deployment.

Refer to the [Outputs](#outputs) section below for a complete list and descriptions.

## Configure

Connect to the integration host by ssh.

There is restriction set for appliance configuration and global organisation on both AM throught LoadBalancer rules and not HTTPS access to Session Manager from outside the VPC.

Use `rdpuser` to connect to the debian integration's instance with RDP. The private key is copied to the user so you can access WALLIX Target on admin interface with it.

You can also use x11 forwarding and run firefox on the Debian Host to access it.

```bash
ssh -Xi ./generated_files/private_key.pem admin@<ip_debian_host>
admin# firefox
```

Connect and configure Access and Session Manager on port 2242 :

- The following setup are not yet automated :
  - Database replication
  - WebUI Admin password and Encryption.

## Replication

If there is 2 Session Manager, a file `./generated_files/info_replication.txt` will be generated. This can be used for extra automation on setting up the replication.
This is not yet shown as an example as bastion replication installation is dependant on the version you use.

## Cost

```txt
 Name                                                       Monthly Qty  Unit              Monthly Cost   
                                                                                                          
 module.instance_bastion[0].aws_instance.wallix                                                           
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 ├─ root_block_device                                                                                     
 │  └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
 └─ ebs_block_device[0]                                                                                   
    └─ Storage (general purpose SSD, gp3)                            31  GB                       $2.73   
                                                                                                          
 module.instance_bastion[1].aws_instance.wallix                                                           
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 ├─ root_block_device                                                                                     
 │  └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
 └─ ebs_block_device[0]                                                                                   
    └─ Storage (general purpose SSD, gp3)                            31  GB                       $2.73   
                                                                                                          
 module.instance_access_manager[0].aws_instance.wallix                                                    
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 ├─ root_block_device                                                                                     
 │  └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
 └─ ebs_block_device[0]                                                                                   
    └─ Storage (general purpose SSD, gp3)                            30  GB                       $2.64   
                                                                                                          
 module.instance_access_manager[1].aws_instance.wallix                                                    
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 ├─ root_block_device                                                                                     
 │  └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
 └─ ebs_block_device[0]                                                                                   
    └─ Storage (general purpose SSD, gp3)                            30  GB                       $2.64   
                                                                                                          
 module.instance_access_manager[2].aws_instance.wallix                                                    
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 ├─ root_block_device                                                                                     
 │  └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
 └─ ebs_block_device[0]                                                                                   
    └─ Storage (general purpose SSD, gp3)                            30  GB                       $2.64   
                                                                                                          
 module.integration_debian[0].aws_instance.debian_admin                                                   
 ├─ Instance usage (Linux/UNIX, on-demand, t3.medium)               730  hours                   $33.29   
 └─ root_block_device                                                                                     
    └─ Storage (general purpose SSD, gp2)                             8  GB                       $0.88   
                                                                                                          
 aws_lb.front_am                                                                                          
 ├─ Application load balancer                                       730  hours                   $18.40   
 └─ Load balancer capacity units                         Monthly cost depends on usage: $5.84 per LCU     
                                                                                                          
 aws_lb.front_sm                                                                                          
 ├─ Network load balancer                                           730  hours                   $18.40   
 └─ Load balancer capacity units                         Monthly cost depends on usage: $4.38 per LCU     
                                                                                                          
 OVERALL TOTAL                                                                                 $255.18 
```

## Known issues

### Debian Terms and Conditions not accepted

You must accept [terms and condition of Debian 12](https://aws.amazon.com/marketplace/pp/prodview-g5rooj5oqzrw4) before use of this template.

### Failing to import certificate on loadbalancer

For some reason, there is sometimes a 403 error while importing a certificate on the LB listener. This is generally due to MFA setup on the account used, and is linked to the rights to access the certificate's vault, as the vault function uses `assume_role`. Please read: [Github issue](https://github.com/hashicorp/terraform-provider-aws/issues/2420).

You may need to manually create the listener and import it before refreshing and re-applying the configuration.

```bash
terraform import aws_lb_listener.Frontend_AM arn:aws:elasticloadbalancing:eu-west-3:519101999238:listener/app/Access-Manager-Front/059ce0c7d3b69254/9c0b0d80abe0ef50
```

If you have imported the listener for the port 80 by mistake, delete the resource target and redo the import.

```bash
terraform destroy -target aws_lb_listener.Frontend_AM
terraform import aws_lb_listener.Frontend_AM arn:aws:elasticloadbalancing:eu-west-3:519101999238:listener/app/Access-Manager-Front/059ce0c7d3b69254/9c0b0d80abe0ef50
```

### I can't access the Debian Machine from my IP

Have you set the allowed ip variable with your public IP ?

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.85.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >=2.3.5 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >=3.4.5 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >=2.5.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.6.3 |
| <a name="requirement_ssh"></a> [ssh](#requirement\_ssh) | >=2.7.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >=4.0.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.5.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |
| <a name="provider_ssh"></a> [ssh](#provider\_ssh) | 2.7.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud-init-am"></a> [cloud-init-am](#module\_cloud-init-am) | ./modules/cloud-init-wallix | n/a |
| <a name="module_cloud-init-sm"></a> [cloud-init-sm](#module\_cloud-init-sm) | ./modules/cloud-init-wallix | n/a |
| <a name="module_instance_access_manager"></a> [instance\_access\_manager](#module\_instance\_access\_manager) | ./modules/aws_wallix_instance | n/a |
| <a name="module_instance_bastion"></a> [instance\_bastion](#module\_instance\_bastion) | ./modules/aws_wallix_instance | n/a |
| <a name="module_integration_debian"></a> [integration\_debian](#module\_integration\_debian) | ./modules/integration_debian_aws | n/a |
| <a name="module_ssh_aws"></a> [ssh\_aws](#module\_ssh\_aws) | ./modules/aws-ssh-key | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_efs_file_system.efs-example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.efs_mount_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_internet_gateway.cluster_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lb.front_am](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.front_sm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.Frontend_AM](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.HTTP_to_HTTPS_Redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.front_end_HTTPS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.front_end_RDP](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.front_end_SSH](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.front_am](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.front_bastion_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.front_bastion_rdp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.front_bastion_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.attach_am](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.attach_sm_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.attach_sm_rdp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.attach_sm_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_network_interface_sg_attachment.wallix-am](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_sg_attachment) | resource |
| [aws_network_interface_sg_attachment.wallix-sm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_sg_attachment) | resource |
| [aws_route.default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group.accessmanager_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.efs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.subnet_az_AM](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.subnet_az_SM](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [local_file.all_ips_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.all_secrets_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.firefox_bookmark_am](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.firefox_bookmark_sm](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.replication_master](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [ssh_resource.copy_bookmarks](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.info_replication](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [tls_private_key.example](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.example](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [http_http.myip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_manager_version"></a> [access\_manager\_version](#input\_access\_manager\_version) | Bastion version to use. It can be partial or full value (12, 11.0 , 10.4.3, 10.0.7.28).<br/> Can be empty for latest pushed image. | `string` | `""` | no |
| <a name="input_alb_internal"></a> [alb\_internal](#input\_alb\_internal) | Should Application Load Balancer be internal ? | `bool` | `false` | no |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | Specifies the ips/networks allowed to access integration instance. e.g: [''10.0.0.0/16'',''90.15.25.21/32''] | `list(any)` | n/a | yes |
| <a name="input_am_disk_size"></a> [am\_disk\_size](#input\_am\_disk\_size) | AM disk sizing | `number` | `30` | no |
| <a name="input_am_disk_type"></a> [am\_disk\_type](#input\_am\_disk\_type) | AM disk type | `string` | `"gp3"` | no |
| <a name="input_ami_from_aws_marketplace"></a> [ami\_from\_aws\_marketplace](#input\_ami\_from\_aws\_marketplace) | Should we use the marketplace image ? If false, the shared image by WALLIX will be use. | `bool` | `true` | no |
| <a name="input_aws_instance_size_am"></a> [aws\_instance\_size\_am](#input\_aws\_instance\_size\_am) | Specifies the instance sizing. | `string` | `"t2.medium"` | no |
| <a name="input_aws_instance_size_debian"></a> [aws\_instance\_size\_debian](#input\_aws\_instance\_size\_debian) | Specifies the instance sizing. | `string` | `"t3.medium"` | no |
| <a name="input_aws_instance_size_sm"></a> [aws\_instance\_size\_sm](#input\_aws\_instance\_size\_sm) | Specifies the instance sizing. | `string` | `"t2.medium"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use! | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Aws region to deploy resources | `string` | n/a | yes |
| <a name="input_bastion_version"></a> [bastion\_version](#input\_bastion\_version) | Bastion version to use. It can be partial or full value (5, 4.0 , 4.4.1, 4.4.1.8).<br/> Can be empty for latest pushed image. | `string` | `""` | no |
| <a name="input_deploy_integration_debian"></a> [deploy\_integration\_debian](#input\_deploy\_integration\_debian) | Should a debian instance for integration be deployed ? | `bool` | `true` | no |
| <a name="input_install_replication"></a> [install\_replication](#input\_install\_replication) | Should we install replication on Session Manager ?<br/> Only valid for bastion 12.0.0 and above. | `bool` | `false` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Name of the key pair that will be use to connect to the instance. | `string` | n/a | yes |
| <a name="input_nlb_internal"></a> [nlb\_internal](#input\_nlb\_internal) | Should Network Load Balancer be internal ?<br/> Setting it to false is risky. | `bool` | `true` | no |
| <a name="input_number_of_am"></a> [number\_of\_am](#input\_number\_of\_am) | Number of AM to be deployed | `number` | `2` | no |
| <a name="input_number_of_sm"></a> [number\_of\_sm](#input\_number\_of\_sm) | Number of SM to be deployed | `number` | `2` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Specifies the project name | `string` | n/a | yes |
| <a name="input_sm_disk_size"></a> [sm\_disk\_size](#input\_sm\_disk\_size) | SM disk sizing | `number` | `31` | no |
| <a name="input_sm_disk_type"></a> [sm\_disk\_type](#input\_sm\_disk\_type) | SM disk type | `string` | `"gp3"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply on resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC, e.g: 10.0.0.0/16 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_ips"></a> [all\_ips](#output\_all\_ips) | All IPs |
| <a name="output_all_secrets"></a> [all\_secrets](#output\_all\_secrets) | All secret |
| <a name="output_am-ami"></a> [am-ami](#output\_am-ami) | Description of the AMI used for Access Manager. |
| <a name="output_am_password_wabadmin"></a> [am\_password\_wabadmin](#output\_am\_password\_wabadmin) | Wabadmin password. |
| <a name="output_am_password_wabsuper"></a> [am\_password\_wabsuper](#output\_am\_password\_wabsuper) | Wabsuper password. |
| <a name="output_am_password_wabupgrade"></a> [am\_password\_wabupgrade](#output\_am\_password\_wabupgrade) | Wabupgrade password. |
| <a name="output_am_private_ip"></a> [am\_private\_ip](#output\_am\_private\_ip) | List of the private ip used for Access Manager. |
| <a name="output_am_url_alb"></a> [am\_url\_alb](#output\_am\_url\_alb) | Url to connect to the AM cluster from Application Load Balancer. |
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | Availability zones of the select region. |
| <a name="output_cloud_init_am"></a> [cloud\_init\_am](#output\_cloud\_init\_am) | Show Cloud-init rendered file for AM |
| <a name="output_cloud_init_sm"></a> [cloud\_init\_sm](#output\_cloud\_init\_sm) | Show Cloud-init rendered file for SM |
| <a name="output_debian_connect"></a> [debian\_connect](#output\_debian\_connect) | How to connect to the Debian instance. |
| <a name="output_debian_public_ip"></a> [debian\_public\_ip](#output\_debian\_public\_ip) | Public IP of the Debian instance. |
| <a name="output_debianpassword_rdpuser"></a> [debianpassword\_rdpuser](#output\_debianpassword\_rdpuser) | Generated password for rdp connexion with rdpuser. |
| <a name="output_efs"></a> [efs](#output\_efs) | FQDN of the EFS |
| <a name="output_sm-ami"></a> [sm-ami](#output\_sm-ami) | Description of the AMI used for Session Manager. |
| <a name="output_sm_fqdn_nlb"></a> [sm\_fqdn\_nlb](#output\_sm\_fqdn\_nlb) | FQDN of the Network Load Balancer. |
| <a name="output_sm_ids"></a> [sm\_ids](#output\_sm\_ids) | List of sm ids. Useful to find the default admin password (admin-<instance-id>) |
| <a name="output_sm_password_crypto"></a> [sm\_password\_crypto](#output\_sm\_password\_crypto) | Bastion passphrase. |
| <a name="output_sm_password_wabadmin"></a> [sm\_password\_wabadmin](#output\_sm\_password\_wabadmin) | Wabadmin password. |
| <a name="output_sm_password_wabsuper"></a> [sm\_password\_wabsuper](#output\_sm\_password\_wabsuper) | Wabsuper password. |
| <a name="output_sm_password_wabupgrade"></a> [sm\_password\_wabupgrade](#output\_sm\_password\_wabupgrade) | Wabupgrade password. |
| <a name="output_sm_password_webui"></a> [sm\_password\_webui](#output\_sm\_password\_webui) | WebUI password. |
| <a name="output_sm_private_ip"></a> [sm\_private\_ip](#output\_sm\_private\_ip) | List of the private ip used for Session Manager. |
| <a name="output_ssh_private_key"></a> [ssh\_private\_key](#output\_ssh\_private\_key) | The SSH Private key in openssh format. |
| <a name="output_warning_allowed_ips_too_wild"></a> [warning\_allowed\_ips\_too\_wild](#output\_warning\_allowed\_ips\_too\_wild) | IP Warnings. |
| <a name="output_warning_nlb_internal_false"></a> [warning\_nlb\_internal\_false](#output\_warning\_nlb\_internal\_false) | NLB Warnings. |
| <a name="output_your-public_ip"></a> [your-public\_ip](#output\_your-public\_ip) | Your egress public IP. |
<!-- END_TF_DOCS -->