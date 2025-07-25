locals {
  project_name = var.project_name
  common_tags  = merge(var.tags, { Project_Name = "${var.project_name}" })

  // generate list of network for SG rules

  all_az1_az2_subnets = concat(aws_subnet.subnet_az_AM[*].cidr_block, aws_subnet.subnet_az_SM[*].cidr_block)
  am_instances        = formatlist("%s/32", module.instance_access_manager[*].instance_private_ip)
  sm_instances        = formatlist("%s/32", module.instance_bastion[*].instance_private_ip)

  am_ids = toset(module.instance_access_manager[*].instance-id)
  sm_ids = toset(module.instance_bastion[*].instance-id)

}
