# Built-in profile of the key: the Bastion refuses a profile created by an administrator
# ("The API key must be associated to a read-only profile").
data "wallix-bastion_profile" "key" {
  profile_name = var.apikey_profile
}

# Changing the profile or the IPs recreates the key.
resource "wallix-bastion_apikey_v2" "reporting" {
  apikey_name   = "${local.name}-reporting"
  description   = "Automation Showroom: reporting tool"
  profile       = data.wallix-bastion_profile.key.profile_name
  ip_limitation = join(",", var.allowed_source_ips)
}
