resource "wallix-bastion_timeframe" "timeframes" {
  for_each = local.timeframes

  timeframe_name = each.key
  description    = each.value.description

  dynamic "periods" {
    for_each = each.value.periods
    content {
      start_date = periods.value.start_date
      end_date   = periods.value.end_date
      start_time = periods.value.start_time
      end_time   = periods.value.end_time
      week_days  = periods.value.week_days
    }
  }
}

resource "wallix-bastion_usergroup" "groups" {
  for_each = local.groups

  group_name  = each.key
  description = each.value.description
  # A timeframe of the inventory, or a built-in one such as allthetime.
  timeframes = [for name in each.value.timeframes : try(wallix-bastion_timeframe.timeframes[name].timeframe_name, name)]
}

resource "wallix-bastion_user" "users" {
  for_each = local.users

  user_name        = each.key
  display_name     = each.value.display_name
  email            = each.value.email
  profile          = each.value.profile
  user_auths       = ["local_password"]
  password         = random_password.users[each.key].result
  force_change_pwd = true
  groups           = [for name in each.value.groups : wallix-bastion_usergroup.groups[name].group_name]
}
