# The groups the delegated administrator is in charge of.
resource "wallix-bastion_usergroup" "team" {
  group_name  = "${local.name}-team"
  description = "Automation Showroom: users managed by the delegated administrator"
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_targetgroup" "team" {
  group_name  = "${local.name}-servers"
  description = "Automation Showroom: targets visible to the delegated administrator"
}

resource "wallix-bastion_profile" "team_admin" {
  profile_name  = "${local.name}-admin"
  description   = "Automation Showroom: manages the users of one team"
  target_access = false # Administration only: no session on the targets.

  # What the profile can see (view) or change (modify), in the web UI and the REST API.
  gui_features {
    users          = "modify"
    user_groups    = "modify"
    devices        = "view"
    target_groups  = "view"
    authorizations = "view"
  }

  # Required block, left empty as in the built-in profiles that can't edit profiles.
  gui_transmission {}

  # The profile only reaches these groups, not the rest of the Bastion.
  user_groups_limitation {
    user_groups = [wallix-bastion_usergroup.team.group_name]
  }

  target_groups_limitation {
    target_groups = [wallix-bastion_targetgroup.team.group_name]
  }
}

resource "random_password" "team_admin" {
  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

resource "wallix-bastion_user" "team_admin" {
  user_name          = "${local.name}-admin"
  display_name       = "Team administrator"
  email              = var.admin_email
  profile            = wallix-bastion_profile.team_admin.profile_name
  user_auths         = ["local_password"]
  password           = random_password.team_admin.result
  force_change_pwd   = false
  preferred_language = "en"
}
