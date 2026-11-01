# Requesters can only log in during business hours; approvers at any time.
resource "wallix-bastion_timeframe" "business_hours" {
  timeframe_name = "${local.name}-business-hours"
  description    = "Working days, ${var.business_hours.start_time} to ${var.business_hours.end_time}"

  periods {
    start_date = var.business_hours.start_date
    end_date   = var.business_hours.end_date
    start_time = var.business_hours.start_time
    end_time   = var.business_hours.end_time
    week_days  = ["monday", "tuesday", "wednesday", "thursday", "friday"]
  }
}

resource "wallix-bastion_usergroup" "requesters" {
  group_name  = "${local.name}-requesters"
  description = "Need an approval to reach the critical servers"
  timeframes  = [wallix-bastion_timeframe.business_hours.timeframe_name]
}

resource "wallix-bastion_usergroup" "approvers" {
  group_name  = "${local.name}-approvers"
  description = "Approve the access requests of the requesters"
  timeframes  = ["allthetime"]
}

resource "random_password" "users" {
  for_each = toset(["requester", "approver"])

  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

resource "wallix-bastion_user" "requester" {
  user_name        = "${local.name}-requester"
  email            = "${local.name}-requester@example.com"
  profile          = "user"
  user_auths       = ["local_password"]
  password         = random_password.users["requester"].result
  force_change_pwd = false
  groups           = [wallix-bastion_usergroup.requesters.group_name]
}

resource "wallix-bastion_user" "approver" {
  user_name        = "${local.name}-approver"
  email            = "${local.name}-approver@example.com"
  profile          = "approver" # Built-in profile allowed to approve requests.
  user_auths       = ["local_password"]
  password         = random_password.users["approver"].result
  force_change_pwd = false
  groups           = [wallix-bastion_usergroup.approvers.group_name]
}
