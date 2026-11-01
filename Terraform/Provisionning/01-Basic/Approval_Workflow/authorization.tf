resource "wallix-bastion_authorization" "critical" {
  authorization_name = "${local.name}-critical"
  description        = "Sessions and password checkout on approval"
  user_group         = wallix-bastion_usergroup.requesters.group_name
  target_group       = wallix-bastion_targetgroup.critical.group_name

  authorize_sessions           = true
  subprotocols                 = ["SSH_SHELL_SESSION"]
  authorize_password_retrieval = true
  is_recorded                  = true
  is_critical                  = true

  # Each request waits for one approval from the approvers group; it expires after approval_timeout minutes.
  approval_required = true
  approvers         = [wallix-bastion_usergroup.approvers.group_name]
  active_quorum     = 1 # Approvals needed during active periods (-1: automatic, 0: none).
  inactive_quorum   = 1 # Approvals needed during inactive periods.
  approval_timeout  = 60
  has_comment       = true
  mandatory_comment = true

  # An approver can join a running session to watch it.
  authorize_session_sharing = true
  session_sharing_mode      = "view_only"
}
