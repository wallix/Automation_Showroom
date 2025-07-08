module "instance_bastion" {
  count                    = var.number_of_sm
  source                   = "./modules/aws_wallix_instance"
  ami_from_aws_marketplace = var.ami_from_aws_marketplace
  aws_instance_size        = var.aws_instance_size_sm
  common_tags              = local.common_tags
  disk_size                = var.sm_disk_size
  disk_type                = var.sm_disk_type
  instance_name            = "SM-${local.project_name}-${count.index}"
  key_pair_name            = module.ssh_aws.key_pair_name
  product_name             = "bastion"
  product_version          = var.bastion_version
  project_name             = local.project_name
  subnet_id                = aws_subnet.subnet_az_SM[count.index].id
  user_data                = module.cloud-init-sm.cloudinit_config
}

module "instance_access_manager" {
  count                    = var.number_of_am
  source                   = "./modules/aws_wallix_instance"
  ami_from_aws_marketplace = var.ami_from_aws_marketplace
  aws_instance_size        = var.aws_instance_size_am
  common_tags              = local.common_tags
  disk_size                = var.am_disk_size
  disk_type                = var.am_disk_type
  instance_name            = "AM-${local.project_name}-${count.index}"
  key_pair_name            = module.ssh_aws.key_pair_name
  product_name             = "access-manager"
  product_version          = var.access_manager_version
  project_name             = local.project_name
  subnet_id                = aws_subnet.subnet_az_AM[count.index].id
  user_data                = module.cloud-init-am.cloudinit_config
}

module "integration_debian" {
  count             = var.deploy_integration_debian ? 1 : 0
  source            = "./modules/integration_debian_aws"
  tags              = local.common_tags
  sm-instances      = local.sm_instances
  project_name      = local.project_name
  am-instances      = local.am_instances
  allowed_ips       = var.allowed_ips
  subnet_id         = try(aws_subnet.subnet_az_AM[0].id, aws_subnet.subnet_az_SM[0].id) // if no am are created, will use the first bastion subnets
  aws_instance_size = var.aws_instance_size_debian
  common_tags       = local.common_tags
  vpc_id            = aws_vpc.cluster.id
  key_pair_name     = module.ssh_aws.key_pair_name
  private_key       = module.ssh_aws.ssh_private_key
  public_ssh_key    = module.ssh_aws.ssh_public_key

}
