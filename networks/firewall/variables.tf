variable "vpc_configurations" {
  type        = any
  description = "vpc configurations"
}

variable "vpc_firewall_rules_config" {
  type        = any
  description = "get firewall configurations"
}

variable "vpc_network" {
  type        = string
  description = "vpc network name"
}
