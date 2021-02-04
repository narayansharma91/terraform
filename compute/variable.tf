variable "vpc_configurations" {
  type        = any
  description = "provide vpc configurations"
}

variable "applications_config_value" {
  type        = any
  description = "getting each application configurations"
}

variable "instance_templates_config" {
  type        = any
  description = "get all instances templates configurations"
}

variable "instance_groups_config" {
  type        = any
  description = "get all instances groups configurations"
}
variable "service_accounts" {
  type        = any
  description = "get all service accounts configurations"
}
variable "service_account_emails" {
  type        = any
  description = "get all service accounts email configurations"
}

variable "vpc_subnets_config" {
  type        = any
  description = "get all subnet configurations"
}
