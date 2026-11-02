locals {
  project_name = var.project_name
  common_tags  = merge(var.tags, { Project_Name = "${var.project_name}" })

  // generate list of network for SG rules

  all_az1_az2_subnets = concat(aws_subnet.subnet_az_AM[*].cidr_block, aws_subnet.subnet_az_SM[*].cidr_block)
  am_instances        = formatlist("%s/32", module.instance_access_manager[*].instance_private_ip)
  sm_instances        = formatlist("%s/32", module.instance_bastion[*].instance_private_ip)

  // The Debian host reaches an internet-facing ALB through its public IP.
  // Indexed reference, not a splat: a splat depends on every module input (AM IPs, hence a cycle).
  alb_allowed_cidrs = concat(var.allowed_ips, [var.vpc_cidr], var.alb_internal || !var.deploy_integration_debian ? [] : ["${module.integration_debian[0].public_ip_debian_admin}/32"])
  // No Debian public IP here: cycle (Debian SG uses SM IPs, SM cloud-init uses the NLB DNS name).
  nlb_allowed_cidrs = concat(var.allowed_ips, [var.vpc_cidr])

  am_ids = toset(module.instance_access_manager[*].instance-id)
  sm_ids = toset(module.instance_bastion[*].instance-id)

}
