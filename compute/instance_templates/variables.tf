variable "instance_templates_config" {
  type        = any
  description = "Instance templates configurations"
}

variable "instance_groups_config" {
  type        = any
  description = "Instance groups configurations"
}

variable "instance_groups" {
  type        = any
  description = "get customized instance groups configurations"
}

variable "service_accounts" {
  type        = any
  description = "service account use for instance template"
}

variable "service_account_emails" {
  type        = any
  description = "all service accounts emails"
}
variable "region" {
  type        = string
  description = "name of the region where you want to deploy/create template"
}

