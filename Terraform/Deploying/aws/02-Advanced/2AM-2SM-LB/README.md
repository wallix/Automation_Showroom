# Deploy WALLIX access manager and Bastion cluster with loadbalancer on AWS

This is an example of AWS deployment with cluster setup.
It contains mutiples modules to help understands the steps of creation.
Those modules can be use independatly, therefore contains their own README.

![Architecture](AWS_2AM-2SM-LB.drawio.png)

## Requirements

* Access and Right to AWS
* AMI were shared by WALLIX Support if not available on MarketPlace.
* terraform is installed

Adapt samples to your needs

```bash
cp lab.auto.tfvars.example lab.auto.tfvars
vi lab.auto.tfvars
```

## Deploy

```bash
terraform init      # initializes the working directory
terraform fmt --recursive      # format files
terraform validate  # validates the configuration files
terraform apply     # apply configuration
```

Some outputs are marked as sensible. Example: `sm_password_wabadmin = <sensitive>`
Use `terraform output <name of the output>` to show them. Example :`terraform output sm_password_wabadmin`

## Configure

Connect to the integration host by ssh.

There is restriction set for appliance configuration and global organisation on both AM throught LoadBalancer rules and not HTTPS access to Session Manager from outside the VPC.

Use `rdpuser` to connect to the debian integration's instance with RDP

You can also use x11 forwarding and run firefox on the Debian Host to access it.

```bash
ssh -Xi private_key.pem admin@<ip_debian_host>
admin# firefox
```

Connect and configure Access and Session Manager on port 2242 :

* The setup of the replication is not automated. (yet!)

## Known issues

### Debian Terms and Conditions not accepted

You must accept [terms and condition of Debian 12](https://aws.amazon.com/marketplace/pp/prodview-l5gv52ndg5q6i) before use of this template.

### Failing to import certificate on loadbalancer

For some reason there is sometimes a 403 error while importing certificate on LB listener, it's linked to the rights to access certificate's vault.
You need to manually create the listener and import it before refreshing and re-apply configuration.

```bash
terraform import aws_lb_listener.Frontend_AM arn:aws:elasticloadbalancing:eu-west-3:519101999238:listener/app/Access-Manager-Front/059ce0c7d3b69254/9c0b0d80abe0ef50
```

### I can't access the Debian Machine from my IP

Have you set the allowed ip variable with your public IP ?

## TO DO

* Keep working on the different README and variable.tf for better clarity.
* Add example of mix and match of modules.
