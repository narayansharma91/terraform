variable "environment" {
  type        = string
  description = "environment name which tranformattion will take place"
}
variable "service_account" {
  type        = string
  default     = "terraform-practice-303405-9bf218db7003.json"
  description = "environment name which tranformattion will take place"
}
variable "provider_info" {
  type        = map
  description = "environment name which tranformattion will take place"
}

##########Networking ##########################

variable "vpc_configurations" {
  type = any
}
variable "vpc_subnets_config" {
  type = any
}

variable "vpc_firewall_rules_config" {
  type        = any
  description = "create all firewall rules"
}

####################### IAM #####################
variable "service_accounts_config" {
  type        = any
  description = "create all service_accounts"
}
variable "services" {
  type        = list
  description = "enable services"
}
variable "iam_roles" {
  type        = list
  description = "iam roles for users"
}

###################### Compute ###################

variable "instance_groups_config" {
  type        = any
  description = ""
}

variable "instance_templates_config" {
  type        = any
  description = ""
}

variable "applications_config" {
  type        = any
  description = ""
}
variable "load_balancer_config" {
  type        = any
  description = ""
}



