resource "cloudngfwaws_security_rule" "example" {
  rulestack   = "terraform-rulestack"
  rule_list   = "LocalRule"
  priority    = 3
  name        = "outbound-app1-vms"
  description = "Also configured by Terraform"
  source {
    prefix_lists = [ cloudngfwaws_prefix_list.app1_vms.name ]
  }
  destination {
    cidrs = ["any"]
  }
  negate_destination = true
  applications       = ["any"]
  category {}
  action        = "Allow"
  logging       = true
  audit_comment = "initial config"
}

resource "cloudngfwaws_prefix_list" "app1_vms" {
  rulestack   = "terraform-rulestack"
  name        = "tf-prefix-list"
  description = "App1 VM Subnets"
  prefix_list = [
    "10.104.0.0/24",
    "10.104.128.0/24",
  ]
  audit_comment = "initial config"
}