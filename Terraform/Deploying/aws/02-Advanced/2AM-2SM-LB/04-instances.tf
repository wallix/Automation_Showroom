module "instance_bastion1" {
  source            = "./modules/aws_wallix_instance"
  wallix_ami        = var.sm_ami
  disk_size         = var.sm_disk_size
  disk_type         = var.sm_disk_type
  aws_instance_size = var.aws_instance_size_sm
  common_tags       = var.tags
  instance_name     = "SM-${local.project_name}-1}"
  key_pair_name     = module.ssh_aws.key_pair_name
  project_name      = local.project_name
  security_group_id = aws_security_group.bastion_sg.id
  subnet_id         = aws_subnet.subnet_az1_SM.id
  user_data         = module.cloud-init-sm.cloudinit_config
}

module "instance_bastion2" {
  source            = "./modules/aws_wallix_instance"
  wallix_ami        = var.sm_ami
  disk_size         = var.sm_disk_size
  disk_type         = var.sm_disk_type
  aws_instance_size = var.aws_instance_size_sm
  common_tags       = var.tags
  instance_name     = "SM-${local.project_name}-2}"
  key_pair_name     = module.ssh_aws.key_pair_name
  project_name      = local.project_name
  security_group_id = aws_security_group.bastion_sg.id
  subnet_id         = aws_subnet.subnet_az2_SM.id
  user_data         = module.cloud-init-sm.cloudinit_config
}

module "instance_access_manager1" {
  source            = "./modules/aws_wallix_instance"
  wallix_ami        = var.am_ami
  disk_size         = var.am_disk_size
  disk_type         = var.am_disk_type
  aws_instance_size = var.aws_instance_size_sm
  common_tags       = var.tags
  instance_name     = "AM-${local.project_name}-1}"
  key_pair_name     = module.ssh_aws.key_pair_name
  project_name      = local.project_name
  security_group_id = aws_security_group.accessmanager_sg.id
  subnet_id         = aws_subnet.subnet_az1_AM.id
  user_data         = module.cloud-init-am.cloudinit_config
}

module "instance_access_manager2" {
  source            = "./modules/aws_wallix_instance"
  wallix_ami        = var.am_ami
  disk_size         = var.am_disk_size
  disk_type         = var.am_disk_type
  aws_instance_size = var.aws_instance_size_sm
  common_tags       = var.tags
  instance_name     = "AM-${local.project_name}-2}"
  key_pair_name     = module.ssh_aws.key_pair_name
  project_name      = local.project_name
  security_group_id = aws_security_group.accessmanager_sg.id
  subnet_id         = aws_subnet.subnet_az2_AM.id
  user_data         = module.cloud-init-am.cloudinit_config
}

module "integration_debian" {
  source            = "./modules/integration_debian_aws"
  tags              = var.tags
  sm-instances      = local.sm_instances
  project_name      = local.project_name
  am-instances      = local.am_instances
  allowed_ips       = var.allowed_ips
  subnet_id         = aws_subnet.subnet_az1_AM.id
  aws_instance_size = var.aws_instance_size_debian
  common_tags       = var.tags
  vpc_id            = aws_vpc.cluster.id
  key_pair_name     = module.ssh_aws.key_pair_name
  private_key       = module.ssh_aws.ssh_private_key

}