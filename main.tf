

provider "google" {
  credentials = file(var.provider_info.service_account)
  project     = var.provider_info.project
}
# terraform {
#   backend "gcs" {
#     bucket  = "<bucketname>"
#     prefix  = "terraform/state"
#     credentials = "<service_account>).json"
#   }
# }

resource "google_project_service" "enabled_services" {
  count                      = length(var.services)
  service                    = var.services[count.index]
  disable_dependent_services = true
}


# # Configure vpc network
module "vpc_networks" {
  source             = "./networks/vpc/"
  vpc_configurations = var.vpc_configurations
  depends_on         = [google_project_service.enabled_services]
}

# # Configure subnets
module "vpc_subnets" {
  source             = "./networks/subnets/"
  for_each           = var.vpc_subnets_config
  vpc_configurations = var.vpc_configurations
  vpc_subnets_config = var.vpc_subnets_config[each.key]
  vpc_network        = each.key
  depends_on         = [module.vpc_networks]
}

# # Configure firewall rules
module "firewall_rules" {
  source                    = "./networks/firewall/"
  for_each                  = var.vpc_subnets_config
  vpc_configurations        = var.vpc_configurations
  vpc_firewall_rules_config = var.vpc_firewall_rules_config[each.key]
  vpc_network               = each.key
  depends_on                = [module.vpc_networks]
}

# Configure IAM & Service Accounts rules
module "iam_service_accounts" {
  source           = "./iam/"
  service_accounts = var.service_accounts_config
  iam_roles        = var.iam_roles
  project          = var.provider_info.project
  depends_on       = [google_project_service.enabled_services]
}



module "compute" {
  source                    = "./compute/"
  for_each                  = var.applications_config
  applications_config_value = var.applications_config[each.key]
  instance_templates_config = var.instance_templates_config
  load_balancer_config      = var.load_balancer_config
  instance_groups_config    = var.instance_groups_config
  service_accounts          = module.iam_service_accounts.service_accounts
  service_account_emails    = module.iam_service_accounts.service_accounts_emails
  vpc_configurations        = var.vpc_configurations
  vpc_subnets_config        = var.vpc_subnets_config
  depends_on                = [module.vpc_subnets]
}

module "network_services" {
  source                 = "./network_services/"
  applications_config    = var.applications_config
  load_balancer_config   = var.load_balancer_config
  instance_groups_config = var.instance_groups_config
  instances_groups_list  = module.compute.*
  depends_on             = [module.compute]
}
