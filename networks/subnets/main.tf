resource "google_compute_subnetwork" "subnets" {
  for_each                 = var.vpc_subnets_config
  name                     = "${var.vpc_configurations[var.vpc_network].vpc_identifier}-${each.key}"
  ip_cidr_range            = var.vpc_subnets_config[each.key].ip_cidr_range
  region                   = var.vpc_subnets_config[each.key].region
  private_ip_google_access = lookup(var.vpc_subnets_config[each.key], "private_ip_google_access", null)
  network                  = var.vpc_network
}