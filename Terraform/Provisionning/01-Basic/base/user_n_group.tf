# Create UserGroup

resource "wallix-bastion_usergroup" "demo" {
  group_name = random_pet.group.id
  timeframes = ["allthetime"]
}



# Configure an user
resource "wallix-bastion_user" "demo" {
  user_name          = random_pet.user.id
  email              = "${random_pet.user.id}@none.none"
  profile            = "user"
  user_auths         = ["local_password", "local_sshkey"]
  force_change_pwd   = false
  preferred_language = "en"
  password           = random_string.demo.result
  ssh_public_key     = tls_private_key.rsa-4096.public_key_openssh
  groups             = [wallix-bastion_usergroup.demo.group_name]

}