locals {
  vpc_identifier = var.vpc_configurations[var.vpc_network].vpc_identifier
}

resource "google_compute_firewall" "default" {
  for_each                = var.vpc_firewall_rules_config
  name                    = "${local.vpc_identifier}-${each.key}"
  network                 = var.vpc_network
  source_ranges           = var.vpc_firewall_rules_config[each.key].source_ranges
  direction               = lookup(var.vpc_firewall_rules_config[each.key], "direction", "INGRESS")
  disabled                = lookup(var.vpc_firewall_rules_config[each.key], "disabled", false)
  priority                = lookup(var.vpc_firewall_rules_config[each.key], "priority", "1000")
  source_service_accounts = lookup(var.vpc_firewall_rules_config[each.key], "source_service_accounts", null)
  target_tags             = lookup(var.vpc_firewall_rules_config[each.key], "target_tags", "") == "" ? null : formatlist("${local.vpc_identifier}-%s", var.vpc_firewall_rules_config[each.key].target_tags)
  target_service_accounts = lookup(var.vpc_firewall_rules_config[each.key], "target_service_accounts", null)
  dynamic "allow" {
    for_each = lookup(var.vpc_firewall_rules_config[each.key], "allow", "") == "" ? [] : var.vpc_firewall_rules_config[each.key].allow
    content {
      protocol = allow.value["protocol"]
      ports    = lookup(allow.value, "ports", null)
    }
  }
  dynamic "deny" {
    for_each = lookup(var.vpc_firewall_rules_config[each.key], "deny", "") == "" ? [] : var.vpc_firewall_rules_config[each.key].deny
    content {
      protocol = deny.value["protocol"]
      ports    = deny.value["ports"]
    }
  }
}
