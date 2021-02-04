resource "google_compute_network" "vpc_networks" {
  for_each                = var.vpc_configurations
  name                    = each.key
  description             = lookup(var.vpc_configurations[each.key], "description", "")
  auto_create_subnetworks = false
}