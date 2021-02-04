# output "final_instance_groups_config_for_lb" {
#   value = local.final_instance_groups_config_for_lb
# }

output "final_instances_groups" {
  value = local.final_instances_groups
}

output "grouping_load_balancers" {
  value = local.final_instance_groups_config_for_lb
}

output "lb_config" {
  value = module.https_load_balancer.*
}
