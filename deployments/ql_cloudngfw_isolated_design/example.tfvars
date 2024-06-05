### GENERAL
name_prefix             = "name-" # TODO: UPDATE TO YOUR NAME
ssh_key_name            = "qwikLABS*"
provider_role           = "CloudNGFWRole"
aws_credentials_profile = "default" # TODO: If running locally, change to a profile with your QwikLabs credentials
region                  = "us-west-2"


global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks Cloud NGFW"
}

### VPC
vpcs = {
  # Do not use `-` in key for VPC as this character is used in concatation of VPC and subnet for module `subnet_set` in `main.tf`
  security_vpc = {
    name = "obew-cgnfw-vpc"
    cidr = "10.100.0.0/16"
    nacls = {}

    security_groups = {
      vmseries_private = {
        name = "vmseries_private"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      "10.100.1.0/24"  = { az = "us-west-2a", set = "tgw_attach", nacl = null }
      "10.100.128.0/24" = { az = "us-west-2b", set = "tgw_attach", nacl = null }
      "10.100.2.0/24"  = { az = "us-west-2a", set = "gwlbe_outbound", nacl = null }
      "10.100.129.0/24" = { az = "us-west-2b", set = "gwlbe_outbound", nacl = null }
      "10.100.3.0/24"   = { az = "us-west-2a", set = "natgw", nacl = null }
      "10.100.130.0/24" = { az = "us-west-2b", set = "natgw", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_rfc1918 = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "cngfw_obew"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_default = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_obew"
        next_hop_type = "gwlbe_endpoint"
      }
      public_default = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      public_rfc1918 = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "cngfw_obew"
        next_hop_type = "gwlbe_endpoint"
      }
      gwlbe_outbound_rfc1918 = {
        vpc_subnet    = "security_vpc-gwlbe_outbound"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_nat_gw"
        next_hop_type = "nat_gateway"
      }
      gwlbe_eastwest_rfc1918 = {
        vpc_subnet    = "security_vpc-gwlbe_outbound"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
    }
  }
  
  app1_vpc = {
    name  = "app1-spoke-vpc"
    cidr  = "10.104.0.0/16"
    nacls = {}
    security_groups = {
      app1_vm = {
        name = "app1_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app1_lb = {
        name = "app1_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "us-west-2a", set = "app1_vm", nacl = null }
      "10.104.128.0/24" = { az = "us-west-2b", set = "app1_vm", nacl = null }
      "10.104.2.0/24"   = { az = "us-west-2a", set = "app1_lb", nacl = null }
      "10.104.130.0/24" = { az = "us-west-2b", set = "app1_lb", nacl = null }
      "10.104.3.0/24"   = { az = "us-west-2a", set = "app1_gwlbe", nacl = null }
      "10.104.131.0/24" = { az = "us-west-2b", set = "app1_gwlbe", nacl = null }
      "10.104.4.0/24"   = { az = "us-west-2a", set = "app1_natgw", nacl = null }
      "10.104.132.0/24" = { az = "us-west-2b", set = "app1_natgw", nacl = null }
      "10.104.5.0/24"   = { az = "us-west-2a", set = "app1_gwlbe2", nacl = null }
      "10.104.133.0/24" = { az = "us-west-2b", set = "app1_gwlbe2", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      gwlbe_default = {
        vpc_subnet    = "app1_vpc-app1_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app1_vpc-app1_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_default = {
        vpc_subnet    = "app1_vpc-app1_natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc_subnet    = "app1_vpc-app1_natgw"
        to_cidr       = "10.104.0.0/24"
        next_hop_key  = "app1_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc_subnet    = "app1_vpc-app1_natgw"
        to_cidr       = "10.104.128.0/24"
        next_hop_key  = "app1_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      app_default = {
        vpc_subnet    = "app1_vpc-app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe1_default = {
        vpc_subnet    = "app1_vpc-app1_gwlbe2"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_nat_gw"
        next_hop_type = "nat_gateway"
      }
    }
  }
  app2_vpc = {
    name  = "app2-spoke-vpc"
    cidr  = "10.105.0.0/16"
    nacls = {}
    security_groups = {
      app2_vm = {
        name = "app2_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app2_lb = {
        name = "app2_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "us-west-2a", set = "app2_vm", nacl = null }
      "10.105.128.0/24" = { az = "us-west-2b", set = "app2_vm", nacl = null }
      "10.105.2.0/24"   = { az = "us-west-2a", set = "app2_lb", nacl = null }
      "10.105.130.0/24" = { az = "us-west-2b", set = "app2_lb", nacl = null }
      "10.105.3.0/24"   = { az = "us-west-2a", set = "app2_gwlbe", nacl = null }
      "10.105.131.0/24" = { az = "us-west-2b", set = "app2_gwlbe", nacl = null }
      "10.105.4.0/24"   = { az = "us-west-2a", set = "app2_natgw", nacl = null }
      "10.105.132.0/24" = { az = "us-west-2b", set = "app2_natgw", nacl = null }
      "10.105.5.0/24"   = { az = "us-west-2a", set = "app2_gwlbe2", nacl = null }
      "10.105.133.0/24" = { az = "us-west-2b", set = "app2_gwlbe2", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      gwlbe_default = {
        vpc_subnet    = "app2_vpc-app2_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app2_vpc-app2_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_default = {
        vpc_subnet    = "app2_vpc-app2_natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc_subnet    = "app2_vpc-app2_natgw"
        to_cidr       = "10.105.0.0/24"
        next_hop_key  = "app2_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc_subnet    = "app2_vpc-app2_natgw"
        to_cidr       = "10.105.128.0/24"
        next_hop_key  = "app2_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      app_default = {
        vpc_subnet    = "app2_vpc-app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe2_default = {
        vpc_subnet    = "app2_vpc-app2_gwlbe2"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_nat_gw"
        next_hop_type = "nat_gateway"
      }
    }
  }
}

### TRANSIT GATEWAY
tgw = {
  create = true
  id     = null
  name   = "tgw"
  asn    = "64512"
  route_tables = {
    # Do not change keys `from_security_vpc` and `from_spoke_vpc` as they are used in `main.tf` and attachments
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
  attachments = {
    # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
    # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
    security = {
      name                = "vmseries"
      vpc_subnet          = "security_vpc-tgw_attach"
      route_table         = "from_security_vpc"
      propagate_routes_to = "from_spoke_vpc"
    }
    app1 = {
      name                = "app1-spoke-vpc"
      vpc_subnet          = "app1_vpc-app1_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
    app2 = {
      name                = "app2-spoke-vpc"
      vpc_subnet          = "app2_vpc-app2_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
  }
}

### NAT GATEWAY
natgws = {
  app1_nat_gw = {
    name       = "natgw"
    vpc_subnet = "app1_vpc-app1_natgw"
  }
  app2_nat_gw = {
    name       = "natgw"
    vpc_subnet = "app2_vpc-app2_natgw"
  }
  cngfw_nat_gw = {
    name       = "natgw"
    vpc_subnet = "security_vpc-natgw"
  }
}

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "us-west-2a"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t3.micro"
  }
  "app1_vm02" = {
    az             = "us-west-2b"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t3.micro"
  }
  "app2_vm01" = {
    az             = "us-west-2a"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t3.micro"
  }
  "app2_vm02" = {
    az             = "us-west-2b"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t3.micro"
  }
}

### SPOKE LOADBALANCERS
spoke_nlbs = {
  "app1-nlb" = {
    vpc_subnet = "app1_vpc-app1_lb"
    vms        = ["app1_vm01", "app1_vm02"]
  }
  "app2-nlb" = {
    vpc_subnet = "app2_vpc-app2_lb"
    vms        = ["app2_vm01", "app2_vm02"]
  }
}

spoke_albs = {
  "app1-alb" = {
    vms = ["app1_vm01", "app1_vm02"]
    rules = {
      "app1" = {
        protocol              = "HTTP"
        port                  = 80
        health_check_port     = "80"
        health_check_matcher  = "200"
        health_check_path     = "/"
        health_check_interval = 10
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_lb"
    security_groups = "app1_lb"
  }
  "app2-alb" = {
    vms = ["app2_vm01", "app2_vm02"]
    rules = {
      "app2" = {
        protocol              = "HTTP"
        port                  = 80
        health_check_port     = "80"
        health_check_matcher  = "200"
        health_check_path     = "/"
        health_check_interval = 10
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_lb"
    security_groups = "app2_lb"
  }
}

cloudngfws = {
  cloudngfws_security = {
    name        = "cloudngfw01"
    vpc_subnet  = "app1_vpc-app1_gwlbe"
    vpc         = "app1_vpc"
    description = "Description"
    security_rules = {
      rule_1 = {
        rule_list                   = "LocalRule"
        priority                    = 500
        name                        = "tf-security-rule"
        description                 = "Also configured by Terraform"
        source_cidrs                = ["any"]
        destination_cidrs           = ["0.0.0.0/0"]
        negate_destination          = false
        protocol                    = "application-default"
        applications                = ["any"]
        category_feeds              = null
        category_url_category_names = null
        action                      = "Allow"
        logging                     = true
        audit_comment               = "initial config"
      }
    }
    log_profiles = {
      dest_1 = {
        create_cw        = true
        name             = "PaloAltoCloudNGFW"
        destination_type = "CloudWatchLogs"
        log_type         = "THREAT"
      }
      dest_2 = {
        create_cw        = true
        name             = "PaloAltoCloudNGFW"
        destination_type = "CloudWatchLogs"
        log_type         = "TRAFFIC"
      }
      dest_3 = {
        create_cw        = true
        name             = "PaloAltoCloudNGFW"
        destination_type = "CloudWatchLogs"
        log_type         = "DECRYPTION"
      }
    }
    profile_config = {
      anti_spyware  = "BestPractice"
      anti_virus    = "BestPractice"
      vulnerability = "BestPractice"
      file_blocking = "BestPractice"
      url_filtering = "BestPractice"
      outbound_trust_certificate = "ca-secrets-manager"
      outbound_untrust_certificate = "ca-secrets-manager"
    }
  }
}

gwlb_endpoints = {
  # Value of `gwlb` must match key of objects stored in `gwlbs`
  # Value of `vpc` must match key of objects stored in `vpcs`
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  app1_inbound = {
    name            = "app1-gwlb-endpoint"
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app1_vpc-app1_lb"
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app1_outbound = {
    name            = "app1-gwlb-out-endpoint"
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_gwlbe2"
    act_as_next_hop = false
    to_vpc_subnets  = null
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app2_inbound = {
    name            = "app2-gwlb-endpoint"
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app2_vpc-app2_lb"
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app2_outbound = {
    name            = "app2-gwlb-out-endpoint"
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_gwlbe2"
    act_as_next_hop = false
    to_vpc_subnets  = null
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  cngfw_obew = {
    name            = "cngfw_obew"
    vpc             = "security_vpc"
    vpc_subnet      = "security_vpc-gwlbe_outbound"
    act_as_next_hop = false
    to_vpc_subnets  = null
    delay           = 0
    service_arn     = "com.amazonaws.vpce.us-west-2.vpce-svc-0c149074b9832e012" # TODO: UPDATE TO YOUR Cloud NGFW Service
  }
}