# How it works
NOTE: this is just blueprint of configurations based IAC which might not works for every application.

* Modify/Create VPC and specify the subnet & firewall rules configurations key in [var_vpc_configurations.auto.tfvars.json](var_vpc_configurations.auto.tfvars.json) file.
* Specify the subnet configurations in  [var_vpc_subnets_config.auto.tfvars.json](var_vpc_subnets_config.auto.tfvars.json) file.
* Specify the firewall rules configurations in [var_vpc_firewall_rules_config.auto.tfvars.json](var_vpc_firewall_rules_config.auto.tfvars.json) file.
* Specify the service accounts and user emails in [var_iam_roles.auto.tfvars.json](var_iam_roles.auto.tfvars.json) file.
* Specify the application configurations in [var_applications_config.auto.tfvars.json](var_applications_config.auto.tfvars.json) file.
* Specify the instance groups configurations in [var_instance_groups_config.auto.tfvars.json](var_instance_groups_config.auto.tfvars.json) file.
* Specify the instance templates in [var_instance_templates_config.auto.tfvars.json](var_instance_templates_config.auto.tfvars.json) file.
* Specify the load balancer configurations in [var_load_balancer_config.auto.tfvars.json](var_load_balancer_config.auto.tfvars.json) file.

# Some important tips while working with terraform
1. If statement in loop, eg
```
[for instance_template in instances_templates:
  ..... your stuff
  if lookup(instance_template, "name", "") == "" ? false : true
]
```
2. Convert list to complex object (key value pair/map) using for loop. eg.
```
{for instance_template in instances_templates:
  instance_template.name => instance_template.id
  if lookup(instance_template, "name", "") == "" ? false : true
}
```
3. Grouping values by common key. eg
```
{for instance_template in instances_templates:
  instance_template.name => instance_template.id ...
}
```
4. Some important functions
```
flatten() 
merge()
lookup()

```
5. Working with large infra.
```
terraform apply/plan -refresh=false
terraform apply/plan -target=module.module_name
```
