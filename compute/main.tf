locals {
  app_config_common = var.applications_config_value
  instance_groups = { for subnet in local.app_config_common.networks.subnets :
    subnet => {
      "vpc_identifier"         = var.vpc_configurations[local.app_config_common.networks.network].vpc_identifier
      "network"                = local.app_config_common.networks.network
      "application_identifier" = local.app_config_common.application_identifier
      "app_container_path"     = local.app_config_common.app_container_path
      "subnet_identifier"      = var.vpc_subnets_config[local.app_config_common.networks.network][subnet].identifier
      "instance_groups"        = local.app_config_common.instance_groups_config
    }
  }
}
module "instance_templates" {
  source                    = "./instance_templates/"
  for_each                  = local.instance_groups
  service_accounts          = var.service_accounts
  service_account_emails    = var.service_account_emails
  instance_groups           = local.instance_groups[each.key]
  instance_groups_config    = var.instance_groups_config
  instance_templates_config = var.instance_templates_config
  region                    = each.key
}

