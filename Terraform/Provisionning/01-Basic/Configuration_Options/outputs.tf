output "banner_read_at_plan" {
  description = "Banner options read from the Bastion when the plan was made."
  # values holds every option read, keys included, so it is sensitive; the banner section is not.
  value = nonsensitive(jsondecode(data.wallix-bastion_configoption.banner.values).banner)
}
