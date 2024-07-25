##### App1 VPC #####

output "application_load_balancers" {
  description = <<-EOF
  FQDNs of Application Load Balancers
  EOF
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}

output "network_load_balancers" {
  description = <<-EOF
  FQDNs of Network Load Balancers.
  EOF
  value       = { for k, v in module.public_nlb : k => v.lb_fqdn }
}

output "cloudngfws" {
  value = module.cloudngfw["cloudngfws_security"].cloudngfw_service_name
}


# output "data_subnet_list" {
#   description = "List of subnet IDs created within `subnet_set` module."
#   value = flatten([
#     for vpc_subnet, subnet_details in module.subnet_sets : [
#       for az, az_details in subnet_details.subnets : az_details.id if length(regexall("natgw", az_details.tags["Name"])) > 0
#     ]
#   ])
# }



# output "subnet_set" {
#   value = module.subnet_sets["security_vpc-natgw"].subnets
# }

# output "subnet_set" {
#   value = { for name , az in module.subnet_sets : [
#     for k, v in az : k => {
#       #name = name
#       az = v.availability_zone
#       id = v.id
#     }
#   ]
# }

#[for _, subnet in var.subnets : subnet.id]


# output "subnet_set" {
#   value = flatten(concat([
#     for k, v in module.subnet_sets : [
#       for sk, sv in v : {
#         subnet_set = k
#         sk = sk
#         sv = sv
#         #az = sv
#         #id = v.id
#       }
#     ]
#   ]))
# }

# output "subnet_names" {
#   value = module.subnet_sets.subnet_names
# }