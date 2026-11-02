resource "wallix-bastion_usergroup" "demo" {
  group_name  = local.name
  description = "Automation Showroom: base example"
  timeframes  = ["allthetime"] # Built-in timeframe: no time restriction.
}

resource "wallix-bastion_user" "demo" {
  user_name          = local.name
  display_name       = "Demo user"
  email              = "${local.name}@example.com"
  profile            = "user" # Built-in profile: access to the targets only, no administration.
  user_auths         = ["local_password", "local_sshkey"]
  password           = random_password.user.result
  ssh_public_key     = tls_private_key.user.public_key_openssh
  force_change_pwd   = false
  preferred_language = "en"
  groups             = [wallix-bastion_usergroup.demo.group_name]
}
