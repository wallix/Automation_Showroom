locals {
  project_name = var.project_name
  primary_az   = "${var.aws-region}a"
  secondary_az = "${var.aws-region}b"

  // generate list of network for SG rules

  all_az1_az2_subnets = concat(aws_subnet.subnet_az_AM.*.cidr_block, aws_subnet.subnet_az_SM.*.cidr_block)
  am_instances        = formatlist("%s/32", module.instance_access_manager[*].instance_private_ip)
  sm_instances        = formatlist("%s/32", module.instance_bastion[*].instance_private_ip)
}