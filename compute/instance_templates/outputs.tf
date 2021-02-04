output "instance_groups" {
  value = merge({ for group in google_compute_region_instance_group_manager.regional_instance_group_manager :
    group.base_instance_name => group.instance_group
    },
    { for group in google_compute_instance_group_manager.zonal_instance_group_manager :
      group.base_instance_name => group.instance_group
    }
  )
}




