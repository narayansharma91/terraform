locals {
  lb_name                    = var.load_balancer_config[var.load_balancer_config_id].lb_name
  lb_config                  = var.load_balancer_config[var.load_balancer_config_id]
  default_services_backends1 = local.lb_config.default_backend.backend_config.instance_groups_config

  default_services_backends = flatten([for group_config_id in local.lb_config.default_backend.backend_config.instance_groups_config :
    [for instances_group in var.final_instance_groups_config_for_lb[group_config_id] :
      var.final_instances_groups[instances_group]
    ] if lookup(var.final_instance_groups_config_for_lb, group_config_id, "") != "" ? true : false
  ])
  other_backekend_services = [for other_backend_service in lookup(local.lb_config, "other_backend_services", {}) :
    {
      path : other_backend_service.path,
      name : other_backend_service.name,
      protocol : other_backend_service.protocol,
      port_name : other_backend_service.port_name,
      instances_groups : flatten([for instance_groups in other_backend_service.backend_config.instance_groups_config :
        [for instance_group in var.final_instance_groups_config_for_lb[instance_groups] :
          var.final_instances_groups[instance_group]
        ] if lookup(var.final_instance_groups_config_for_lb, instance_groups, "") == "" ? false : true
    ]) }
  ]
}

resource "google_compute_global_forwarding_rule" "http-lb" {
  name       = "${local.lb_name}-http-ft"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "${local.lb_name}-target-proxy"
  description = "a description"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = local.lb_name
  description     = "a description"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "other-paths"
  }

  path_matcher {
    name            = "other-paths"
    default_service = google_compute_backend_service.default.id

    dynamic "path_rule" {
      for_each = local.other_backekend_services
      content {
        paths   = [path_rule.value["path"]]
        service = google_compute_backend_service.other_backend_services[path_rule.key].id
      }
    }
  }
}

resource "google_compute_backend_service" "default" {
  name          = "${local.lb_name}-${local.lb_config.default_backend.name}"
  port_name     = local.lb_config.default_backend.port_name
  protocol      = local.lb_config.default_backend.protocol
  timeout_sec   = 10
  health_checks = [google_compute_http_health_check.default.id]
  dynamic "backend" {
    for_each = local.default_services_backends
    content {
      group = backend.value
    }
  }
}

resource "google_compute_backend_service" "other_backend_services" {
  count         = length(local.other_backekend_services)
  name          = "${local.lb_name}-${local.other_backekend_services[count.index].name}"
  port_name     = local.other_backekend_services[count.index].port_name
  protocol      = local.other_backekend_services[count.index].protocol
  timeout_sec   = 10
  health_checks = [google_compute_http_health_check.default.id]
  dynamic "backend" {
    for_each = local.other_backekend_services[count.index].instances_groups
    content {
      group = backend.value
    }
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "${local.lb_name}-hc"
  request_path       = local.lb_config.health_check.request_path
  check_interval_sec = local.lb_config.health_check.check_interval_sec
  timeout_sec        = local.lb_config.health_check.timeout_sec
}