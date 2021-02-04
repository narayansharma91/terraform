locals {
  grouping_load_balancer_instance_groups = { for key, app_config in var.applications_config :
    app_config.load_balancer_config => { for app_subnet in var.applications_config[key].networks.subnets :
      app_config.application_identifier => [for key, instance_group_config in var.applications_config[key].instance_groups_config :
        { key : instance_group_config, value : "${var.instance_groups_config[instance_group_config].name}-${lookup(var.instance_groups_config[instance_group_config], "distribution_policy_zones", "") == "" ? "${app_subnet}-${var.instance_groups_config[instance_group_config].zone}" : app_subnet}" }
      ]...
    }...
  }
  flatten_load_balancer_instance_groups = flatten([for key, load_balancer_config in local.grouping_load_balancer_instance_groups :
    flatten([for app_key, app_config in load_balancer_config :
      [for app_id in keys(app_config) :
        flatten(app_config[app_id])
      ]
    ])
  ])

  # final_instance_groups_config_for_lb = { for key, load_balancer_config in local.flatten_load_balancer_instance_groups :
  #   key => { for app_key, app_config in load_balancer_config :
  #     app_key => { for key, value in app_config :
  #       value.key => value.value...
  #     }
  #   }
  # }

  final_instance_groups_config_for_lb = { for key, load_balancer_config in local.flatten_load_balancer_instance_groups :
    load_balancer_config.key => load_balancer_config.value...
  }

  instances_groups = flatten([for key, application_configs in var.instances_groups_list :
    [for application_config in keys(application_configs) :
      [for instance_groups in var.instances_groups_list[key][application_config].instances_groups :
        [for region in keys(instance_groups) :
          [for instance_group in keys(instance_groups[region].instance_groups) :
            { instance_group_name : instance_group, url : instance_groups[region].instance_groups[instance_group] }
          ]
        ]
      ]
    ]
  ])
  final_instances_groups = { for instances_group in local.instances_groups :
    instances_group.instance_group_name => instances_group.url
  }
  grouping_load_balancers = { for application_config_key, application_config in var.applications_config :
    application_config.load_balancer_config => application_config_key...
  }
}

module "https_load_balancer" {
  source   = "./load_balancers/"
  for_each = local.grouping_load_balancers
  # grouping_load_balancers_value = local.grouping_load_balancers[each.key]
  applications_config                 = var.applications_config
  load_balancer_config                = var.load_balancer_config
  instance_groups_config              = var.instance_groups_config
  final_instance_groups_config_for_lb = local.final_instance_groups_config_for_lb
  final_instances_groups              = local.final_instances_groups
  load_balancer_config_id             = each.key
}
