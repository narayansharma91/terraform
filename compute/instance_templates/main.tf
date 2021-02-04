locals {
  service_accounts = { for key, service_account in var.service_account_emails :
    service_account.account_id => service_account.email
  }
  zonal_instance_resources = [for group_config in var.instance_groups.instance_groups :
    {
      "template_info" = var.instance_templates_config[var.instance_groups_config[group_config].instance_templates_config]
      vpc_identifier  = var.instance_groups.vpc_identifier
      "instance_group_info" = merge({
        instance_group_name = "${var.instance_groups_config[group_config].name}-${var.region}-${var.instance_groups_config[group_config].zone}"
      }, var.instance_groups_config[group_config])
    } if lookup(var.instance_groups_config[group_config], "distribution_policy_zones", "") == "" ? true : false
  ]
  regional_instance_resources = [for group_config in var.instance_groups.instance_groups : {
    "template_info" = var.instance_templates_config[var.instance_groups_config[group_config].instance_templates_config]
    vpc_identifier  = var.instance_groups.vpc_identifier
    "instance_group_info" = merge({
      instance_group_name = "${var.instance_groups_config[group_config].name}-${var.region}"
    }, var.instance_groups_config[group_config])
    } if lookup(var.instance_groups_config[group_config], "distribution_policy_zones", "") == "" ? false : true
  ]
  instance_groups = var.instance_groups
}

# data "google_compute_image" "ubuntu" {
#   family  = "cos-85-lts"
#   project = "cos-cloud"
# }

resource "google_compute_instance_template" "zonal_instance_template" {
  count       = length(local.zonal_instance_resources)
  name_prefix = "${var.instance_groups.application_identifier}-${var.instance_groups.subnet_identifier}-${local.zonal_instance_resources[count.index].template_info.name_infix}-"
  description = "This template is used to create app server instances."

  tags = formatlist("${local.zonal_instance_resources[count.index].vpc_identifier}-%s", local.zonal_instance_resources[count.index].template_info.tags)

  labels = local.zonal_instance_resources[count.index].template_info.labels

  machine_type   = local.zonal_instance_resources[count.index].template_info.machine_type
  can_ip_forward = false
  region         = "${var.region}"

  disk {
    source_image = "projects/cos-cloud/global/images/cos-85-13310-1041-161" #data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interface {
    network    = var.instance_groups.network
    subnetwork = "${var.instance_groups.vpc_identifier}-${var.region}"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = local.service_accounts[local.zonal_instance_resources[count.index].template_info.service_account]
    scopes = ["cloud-platform"]
  }

  metadata = {
    google-logging-enabled    = true
    gce-container-declaration = "spec:\n  containers:\n    - name: p-vpc-ase-abc-prempt-tempt-2\n      image: '${var.instance_groups.app_container_path}'\n      stdin: false\n      tty: false\n  restartPolicy: Always\n\n# This container declaration format is not public API and may change without notice. Please\n# use gcloud command-line tool or Google Cloud Console to run Containers on Google Compute Engine."
  }
}


resource "google_compute_instance_template" "regional_instance_template" {
  count       = length(local.regional_instance_resources)
  name_prefix = "${var.instance_groups.application_identifier}-${var.instance_groups.subnet_identifier}-${local.regional_instance_resources[count.index].template_info.name_infix}-"
  description = "This template is used to create app server instances."

  tags = formatlist("${local.regional_instance_resources[count.index].vpc_identifier}-%s", local.regional_instance_resources[count.index].template_info.tags)

  labels = local.regional_instance_resources[count.index].template_info.labels

  machine_type   = local.regional_instance_resources[count.index].template_info.machine_type
  can_ip_forward = false
  region         = "${var.region}"

  disk {
    source_image = "projects/cos-cloud/global/images/cos-85-13310-1041-161" #data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interface {
    network    = var.instance_groups.network
    subnetwork = "${var.instance_groups.vpc_identifier}-${var.region}"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = local.service_accounts[local.regional_instance_resources[count.index].template_info.service_account]
    scopes = ["cloud-platform"]
  }

  metadata = {
    google-logging-enabled    = true
    gce-container-declaration = "spec:\n  containers:\n    - name: p-vpc-ase-abc-prempt-tempt-2\n      image: '${var.instance_groups.app_container_path}'\n      stdin: false\n      tty: false\n  restartPolicy: Always\n\n# This container declaration format is not public API and may change without notice. Please\n# use gcloud command-line tool or Google Cloud Console to run Containers on Google Compute Engine."
  }
}

resource "google_compute_instance_group_manager" "zonal_instance_group_manager" {
  count              = length(local.zonal_instance_resources)
  name               = local.zonal_instance_resources[count.index].instance_group_info.instance_group_name
  base_instance_name = local.zonal_instance_resources[count.index].instance_group_info.instance_group_name
  zone               = "${var.region}-${local.zonal_instance_resources[count.index].instance_group_info.zone}"
  target_size        = local.zonal_instance_resources[count.index].instance_group_info.target_size
  version {
    instance_template = google_compute_instance_template.zonal_instance_template[count.index].id
  }

  dynamic "named_port" {
    for_each = lookup(local.zonal_instance_resources[count.index].instance_group_info, "named_port", "") == "" ? [] : local.zonal_instance_resources[count.index].instance_group_info.named_port
    content {
      name = named_port.value["name"]
      port = named_port.value["port"]
    }
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.zonal_ig_health_check[count.index].id
    initial_delay_sec = local.zonal_instance_resources[count.index].instance_group_info.auto_healing_policies.initial_delay_sec
  }
}

resource "google_compute_health_check" "zonal_ig_health_check" {
  count              = length(local.zonal_instance_resources)
  name               = "${local.zonal_instance_resources[count.index].instance_group_info.instance_group_name}-hc"
  timeout_sec        = local.zonal_instance_resources[count.index].instance_group_info.health_check.timeout_sec
  check_interval_sec = local.zonal_instance_resources[count.index].instance_group_info.health_check.check_interval_sec
  tcp_health_check {
    port = local.zonal_instance_resources[count.index].instance_group_info.health_check.port
  }
}

resource "google_compute_autoscaler" "zonal_application_autoscaller" {
  count  = length(local.zonal_instance_resources)
  name   = "${local.zonal_instance_resources[count.index].instance_group_info.instance_group_name}-auto-scaller"
  zone   = "${var.region}-${local.zonal_instance_resources[count.index].instance_group_info.zone}"
  target = google_compute_instance_group_manager.zonal_instance_group_manager[count.index].id
  autoscaling_policy {
    max_replicas    = local.zonal_instance_resources[count.index].instance_group_info.autoscaler_config.max_replicas
    min_replicas    = local.zonal_instance_resources[count.index].instance_group_info.autoscaler_config.min_replicas
    cooldown_period = local.zonal_instance_resources[count.index].instance_group_info.autoscaler_config.cooldown_period

    cpu_utilization {
      target = local.zonal_instance_resources[count.index].instance_group_info.autoscaler_config.cpu_utilization.target
    }
  }
}

resource "google_compute_region_instance_group_manager" "regional_instance_group_manager" {
  count              = length(local.regional_instance_resources)
  name               = local.regional_instance_resources[count.index].instance_group_info.instance_group_name
  base_instance_name = local.regional_instance_resources[count.index].instance_group_info.instance_group_name
  region             = var.region
  target_size        = local.regional_instance_resources[count.index].instance_group_info.target_size
  version {
    instance_template = google_compute_instance_template.regional_instance_template[count.index].id
  }

  dynamic "named_port" {
    for_each = lookup(local.regional_instance_resources[count.index].instance_group_info, "named_port", "") == "" ? [] : local.regional_instance_resources[count.index].instance_group_info.named_port
    content {
      name = named_port.value["name"]
      port = named_port.value["port"]
    }
  }
  distribution_policy_zones = [for distribution in local.regional_instance_resources[count.index].instance_group_info.distribution_policy_zones :
    "${var.region}-${distribution}"
  ]
  auto_healing_policies {
    health_check      = google_compute_health_check.regional_ig_health_check[count.index].id
    initial_delay_sec = local.regional_instance_resources[count.index].instance_group_info.auto_healing_policies.initial_delay_sec
  }
}


resource "google_compute_health_check" "regional_ig_health_check" {
  count              = length(local.regional_instance_resources)
  name               = "${local.regional_instance_resources[count.index].instance_group_info.instance_group_name}-hc"
  timeout_sec        = local.regional_instance_resources[count.index].instance_group_info.health_check.timeout_sec
  check_interval_sec = local.regional_instance_resources[count.index].instance_group_info.health_check.check_interval_sec
  tcp_health_check {
    port = local.regional_instance_resources[count.index].instance_group_info.health_check.port
  }
}


resource "google_compute_region_autoscaler" "regional_application_autoscaller" {
  count  = length(local.regional_instance_resources)
  name   = "${local.regional_instance_resources[count.index].instance_group_info.instance_group_name}-auto-scaller"
  region = var.region
  target = google_compute_region_instance_group_manager.regional_instance_group_manager[count.index].id
  autoscaling_policy {
    max_replicas    = local.regional_instance_resources[count.index].instance_group_info.autoscaler_config.max_replicas
    min_replicas    = local.regional_instance_resources[count.index].instance_group_info.autoscaler_config.min_replicas
    cooldown_period = local.regional_instance_resources[count.index].instance_group_info.autoscaler_config.cooldown_period

    cpu_utilization {
      target = local.regional_instance_resources[count.index].instance_group_info.autoscaler_config.cpu_utilization.target
    }
  }
}
