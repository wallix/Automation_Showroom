locals {
  project_name = var.project_name
  primary_az   = "${var.aws-region}a"
  secondary_az = "${var.aws-region}b"

  // generate list of network for SG rules

  all_az1_az2_subnets = [
    var.subnet_az1_AM,
    var.subnet_az2_AM,
    var.subnet_az1_SM,
    var.subnet_az2_SM,
  ]

  am_instances = ["${module.instance_access_manager1.instance_private_ip}/32", "${module.instance_access_manager2.instance_private_ip}/32"]
  sm_instances = ["${module.instance_bastion1.instance_private_ip}/32", "${module.instance_bastion2.instance_private_ip}/32"]

}
