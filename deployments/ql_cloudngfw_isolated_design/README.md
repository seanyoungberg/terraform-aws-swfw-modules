# 1. AWS Cloud NGFW Lab

## 1.1. Introduction

This repository and associated code is intended for a specific lab scenario for learning. Nothing here should be referenced or intended for production use.

## 1.2. Navigation

### Outline

Session 1
- Start QL
- Create IAM Role
- Onboard Account
- Set permission on user for AWS account
- Deploy infra (isolated)
  - Includes Panorama
- Create policies in existing rulestack
  - Figure out terraform
- Publish logs/metrics to cloudwatch
- Validate traffic flows

### TOC

- [1. AWS Cloud NGFW Lab](#1-aws-cloud-ngfw-lab)
  - [1.1. Introduction](#11-introduction)
  - [1.2. Navigation](#12-navigation)
    - [Outline](#outline)
    - [TOC](#toc)
  - [1.3. Isolated Design model](#13-isolated-design-model)
- [2. Lab Session 1](#2-lab-session-1)
  - [2.1. Initialize Qwiklab](#21-initialize-qwiklab)
    - [2.1.1. Find SSH Key Pair Name](#211-find-ssh-key-pair-name)
  - [2.2. Update IAM Policies](#22-update-iam-policies)
  - [2.3. Check Marketplace Subscriptions](#23-check-marketplace-subscriptions)
  - [2.4. Launch CloudShell](#24-launch-cloudshell)
  - [2.5. Download Terraform](#25-download-terraform)
  - [2.6. Clone Deployment Git Repository](#26-clone-deployment-git-repository)
  - [2.7. 3.8 Create IAM role for Cloud NGFW](#27-38-create-iam-role-for-cloud-ngfw)
  - [2.8. Manually Onboard Qwiklabs Account](#28-manually-onboard-qwiklabs-account)
  - [2.9. Deploy AWS Infrastructure and Cloud NGFW Isolated Model](#29-deploy-aws-infrastructure-and-cloud-ngfw-isolated-model)
  - [2.10. Reference](#210-reference)
    - [2.10.1. Requirements](#2101-requirements)
    - [2.10.2. Providers](#2102-providers)
    - [2.10.3. Modules](#2103-modules)
    - [2.10.4. Resources](#2104-resources)
    - [2.10.5. Inputs](#2105-inputs)
    - [2.10.6. Outputs](#2106-outputs)

## 1.3. Isolated Design model
- Same Firewall Cluster(s) to inspect applications in multiple VPCs.
- Transparently insert inspection in your application VPCs for both Ingress and Egress Traffic.
- No TGW resource is required.
- E/W Inspection not supported for this model

![image](https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules/assets/9754982/a1b04cd9-2324-4488-a104-34fdb15e4254)


# 2. Lab Session 1
## 2.1. Initialize Qwiklab

- Download `Student Lab Details` File from Qwiklabs interface for later reference
- Click Open Console and authenticate to AWS account with credentials displayed in Qwiklabs
- Verify your selected region in AWS console (top right) matches the aws-gwlb-lab-secrets.txt
- Open the [quiz](https://docs.google.com/forms/d/e/1FAIpQLSfkJdW2cz8kurjB0n7M-WvFOaqfRCuY6OemWf6okQheGO5LMQ/viewform) to answer questions as you go through the guide
  
### 2.1.1. Find SSH Key Pair Name

- EC2 Console -> Key pairs
- Copy and record the name of the Key Pair that was generated by Qwiklabs, e.g. `qwikLABS-L17939-10286`
- In Qwiklabs console, download the ssh key for later use (PEM and PPK options available)

> &#8505; Any EC2 Instance must be associated with a SSH key pair, which is the default method of initial interactive login to EC2 instances. With successful bootstrapping, there should not be any need to connect to the VM-Series instances directly with this key, but it is usually good to keep this key securely stored for any emergency backdoor access. 
> 
> For this lab, we will use the key pair automatically generated by Qwiklabs. The key will also be used for connecting to the test web server instances.


## 2.2. Update IAM Policies


- Search for `IAM` in top search bar (IAM is global)
- In IAM dashboard select Users -> awsstudent
- Expand `default_policy`, Edit Policy -> Visual Editor
- Find the Deny Action for `Cloud Shell` and click `Remove` on the right
- Select `Review policy`
- Select `Save changes`

---

<img src="https://user-images.githubusercontent.com/43679669/200521132-07ca60f0-2186-49cc-b6ac-4c3477de3abf.png" width=50% height=50%>


> &#8505; Qwiklabs has an explicit Deny for CloudShell. However, we have permissions to remove this deny policy. Take a look at the other Deny statements while you are here.

> &#8505; It is important to be familiar with IAM concepts for Cloud NGFW deployments. Several features (such as bootstrap, custom metrics, cloudwatch logs, HA, VM Monitoring) require IAM permissions. You also need to consider IAM permissions in order to deploy with IaC or if using lambda for custom automation.

---

## 2.3. Check Marketplace Subscriptions

> &#8505; Before you can launch Panorama images in an account, the account must first have accepted the Marketplace License agreement for that product.

> &#8505; The QwikLabs accounts should already be subscribed to these offers, but we will need to verify and correct if required.

- Search for `AWS Marketplace Subscriptions` in top search bar
- Verify that there is an active subscription for:
  - `Palo Alto Networks Panorama`

<img src="https://user-images.githubusercontent.com/43679669/210279563-6e313499-41fb-42b3-b516-636df544c6e6.gif" width=50% height=50%>

- If you have both subscriptions, continue to the next section
- If you are missing either subscription, select `Discover Products` and search for `palo alto`
- Select `Palo Alto Networks Panorama` as needed
- Continue to Subscribe
- Accept Terms
- Allow a few moments for the Subscription to be processed
- Repeat for the other Subscription if needed
- Exit out of the Marketplace
- Notify lab instructor if you have any issues

---

## 2.4. Launch CloudShell

- *Verify you are in the assigned region!*
- Search for `cloudshell` in top search bar
- Close out of the Intro Screen
- Allow a few moments for it to initialize

---

> &#8505; This lab will use cloudshell for access to AWS CLI and as a runtime environment to provision your lab resources in AWS using terraform. Cloudshell will have the same IAM role as your authenticated user and has some utilities (git, aws cli, etc) pre-installed. It is only available in limited regions currently.
>
> Anything saved in home directory `/home/cloudshell-user` will remain persistent if you close and relaunch CloudShell

---

## 2.5. Download Terraform 

- Make sure CloudShell home directory is clean

```
rm -rf ~/bin && rm -rf ~/lab-aws-gwlb-vmseries/ && rm -rf ~/terraform-aws-swfw-modules/
```

- Download Terraform in Cloudshell

```
mkdir /home/cloudshell-user/bin/ && wget https://releases.hashicorp.com/terraform/1.3.9/terraform_1.3.9_linux_amd64.zip && unzip terraform_1.3.9_linux_amd64.zip && rm terraform_1.3.9_linux_amd64.zip && mv terraform /home/cloudshell-user/bin/terraform
```

- Verify Terraform 1.3.9 is installed
```
terraform version
```

> &#8505; Terraform projects often have version constraints in the code to protect against potentially breaking syntax changes when new version is released. For this project, the [version constraint](https://github.com/PaloAltoNetworks/lab-aws-gwlb-vmseries/blob/main/terraform/vmseries/versions.tf) is:
> ```
> terraform {
>  required_version = ">=0.12.29, <2.0"
>}
>```
>
>Terraform is distributed as a single binary so isn't usually managed by OS package managers. It simply needs to be downloaded and put into a system `$PATH` location. For Cloudshell, we are using the `/home/cloud-shell-user/bin/` so it will be persistent if the sessions times out.


## 2.6. Clone Deployment Git Repository 

- Clone the Repository with the terraform to deploy
  
```
git clone https://github.com/seanyoungberg/terraform-aws-swfw-modules.git && cd /home/cloudshell-user/terraform-aws-swfw-modules/deployments/iam_roles_cloudngfw && git checkout cloudngfw
```


## 2.7. 3.8 Create IAM role for Cloud NGFW

You will authenticate against your Cloud NGFW by assuming roles in your AWS account that are allowed to make API calls to the AWS API Gateway service. The associated tags with the roles dictate the type of Cloud NGFW programmatic access granted — Firewall Admin, RuleStack Admin, or Global Rulestack Admin.

- Rename example.tfvars to terraform.tfvars
- Update terraform.tfvars with your QwikLabs AWS Account ID
- Initialize and Apply Terraform


## 2.8. Manually Onboard Qwiklabs Account

- Navigate to the [Cloud NGFW web console](https://web.aws.cloudngfw.paloaltonetworks.com/)
- Authenticate with PANW SSO
- Settings -> AWS Accounts -> Add AWS Account
- Enter Account ID -> Download Cloud Formation Template
- Create Cloud Formation Stack with downloaded template
- Enter TrustedAccount ID and ExternalID from Cloud NGFW Console
- Use Outputs from Stack to enter the IAM role ARNs for the QwikLab AWS account into Cloud NGFW Console

## 2.9. Deploy AWS Infrastructure and Cloud NGFW Isolated Model

- Delete .terraform from iam deployment to free up space in cloudshell
`rm -rf ~/terraform-aws-swfw-modules/deployments/iam_roles_cloudngfw/.terraform`
- Move to deployment directory
`
- Rename example.tfvars to terraform.tfvars
- Update terraform.tfvars with your QwikLabs AWS Account ID and SSH Key Name (Found in EC2 Console)
- Initialize and Apply Terraform


## 2.10. Reference
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### 2.10.1. Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.17 |
| <a name="requirement_cloudngfwaws"></a> [cloudngfwaws](#requirement\_cloudngfwaws) | 2.0.6 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.11.1 |

### 2.10.2. Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.17 |

### 2.10.3. Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudngfw"></a> [cloudngfw](#module\_cloudngfw) | ../../modules/cloudngfw | n/a |
| <a name="module_gwlbe_endpoint"></a> [gwlbe\_endpoint](#module\_gwlbe\_endpoint) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_public_alb"></a> [public\_alb](#module\_public\_alb) | ../../modules/alb | n/a |
| <a name="module_public_nlb"></a> [public\_nlb](#module\_public\_nlb) | ../../modules/nlb | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

### 2.10.4. Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.spoke_vm_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.spoke_vm_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.spoke_vm_iam_instance_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.spoke_vms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_kms_alias.current_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |

### 2.10.5. Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudngfws"></a> [cloudngfws](#input\_cloudngfws) | A map defining Cloud NGFWs.<br><br>Following properties are available:<br>- `name`       : name of CloudNGFW<br>- `vpc_subnet` : key of the VPC and subnet connected by '-' character<br>- `vpc`        : key of the VPC<br>- `description`: Use for internal purposes.<br>- `security_rules`: Security Rules definition.<br>- `log_profiles`: Log Profile definition.<br><br>Example:<pre>cloudngfws = {<br>  cloudngfws_security = {<br>    name        = "cloudngfw01"<br>    vpc_subnet  = "app_vpc-app_gwlbe"<br>    vpc         = "app_vpc"<br>    description = "description"<br>    security_rules = <br>    { <br>      rule_1 = { <br>        rule_list                   = "LocalRule"<br>        priority                    = 3<br>        name                        = "tf-security-rule"<br>        description                 = "Also configured by Terraform"<br>        source_cidrs                = ["any"]<br>        destination_cidrs           = ["0.0.0.0/0"]<br>        negate_destination          = false<br>        protocol                    = "application-default"<br>        applications                = ["any"]<br>        category_feeds              = null<br>        category_url_category_names = null<br>        action                      = "Allow"<br>        logging                     = true<br>        audit_comment               = "initial config"<br>      }<br>    }<br>    log_profiles = {  <br>      dest_1 = {<br>        create_cw        = true<br>        name             = "PaloAltoCloudNGFW"<br>        destination_type = "CloudWatchLogs"<br>        log_type         = "THREAT"<br>      }<br>      dest_2 = {<br>        create_cw        = true<br>        name             = "PaloAltoCloudNGFW"<br>        destination_type = "CloudWatchLogs"<br>        log_type         = "TRAFFIC"<br>      }<br>      dest_3 = {<br>        create_cw        = true<br>        name             = "PaloAltoCloudNGFW"<br>        destination_type = "CloudWatchLogs"<br>        log_type         = "DECRYPTION"<br>      }<br>    }<br>    profile_config = {<br>      anti_spyware  = "BestPractice"<br>      anti_virus    = "BestPractice"<br>      vulnerability = "BestPractice"<br>      file_blocking = "BestPractice"<br>      url_filtering = "BestPractice"<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name           = string<br>    vpc_subnet     = string<br>    vpc            = string<br>    description    = string<br>    security_rules = map(any)<br>    log_profiles   = map(any)<br>    profile_config = map(any)<br>  }))</pre> | `{}` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoints"></a> [gwlb\_endpoints](#input\_gwlb\_endpoints) | A map defining GWLB endpoints.<br><br>Following properties are available:<br>- `name`: name of the GWLB endpoint<br>- `vpc`: key of VPC<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic<br>- `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint<br>- `delay`: number of seconds between adding endpoint to routing table<br>- `cloudngfw`: key of the cloudngfw correspond with the endpoints<br><br>Example:<pre>gwlb_endpoints = {<br>  security_gwlb_eastwest = {<br>    name            = "eastwest-gwlb-endpoint"<br>    vpc             = "security_vpc"<br>    vpc_subnet      = "security_vpc-gwlbe_eastwest"<br>    act_as_next_hop = false<br>    to_vpc_subnets  = null<br>    delay           = 60<br>    cloudngfw       = "cloudngfw"<br>  }<br>}</pre> | <pre>map(object({<br>    name            = string<br>    vpc             = string<br>    vpc_subnet      = string<br>    act_as_next_hop = bool<br>    to_vpc_subnets  = string<br>    delay           = number<br>    cloudngfw       = string<br>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_natgws"></a> [natgws](#input\_natgws) | A map defining NAT Gateways.<br><br>Following properties are available:<br>- `name`: name of NAT Gateway<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br><br>Example:<pre>natgws = {<br>  security_nat_gw = {<br>    name       = "natgw"<br>    vpc_subnet = "security_vpc-natgw"<br>  }<br>}</pre> | <pre>map(object({<br>    name       = string<br>    vpc_subnet = string<br>  }))</pre> | `{}` | no |
| <a name="input_provider_account"></a> [provider\_account](#input\_provider\_account) | The AWS Account where the resources should be deployed. | `string` | n/a | yes |
| <a name="input_provider_role"></a> [provider\_role](#input\_provider\_role) | The predifined AWS assumed role for CloudNGFW. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_spoke_albs"></a> [spoke\_albs](#input\_spoke\_albs) | A map defining Application Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `rules`: Rules defining the method of traffic balancing<br>- `vms`: Instances to be the target group for ALB<br>- `vpc`: The VPC in which the load balancer is to be run<br>- `vpc_subnet`: The subnets in which the Load Balancer is to be run<br>- `security_gropus`: Security Groups to be associated with the ALB<pre></pre> | <pre>map(object({<br>    rules           = any<br>    vms             = list(string)<br>    vpc             = string<br>    vpc_subnet      = string<br>    security_groups = string<br>  }))</pre> | n/a | yes |
| <a name="input_spoke_nlbs"></a> [spoke\_nlbs](#input\_spoke\_nlbs) | A map defining Network Load Balancers deployed in spoke VPCs.<br><br>Following properties are available:<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `vms`: keys of spoke VMs<br><br>Example:<pre>spoke_lbs = {<br>  "app1-nlb" = {<br>    vpc_subnet = "app1_vpc-app1_lb"<br>    vms        = ["app1_vm01", "app1_vm02"]<br>  }<br>}</pre> | <pre>map(object({<br>    vpc_subnet = string<br>    vms        = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_spoke_vms"></a> [spoke\_vms](#input\_spoke\_vms) | A map defining VMs in spoke VPCs.<br><br>Following properties are available:<br>- `az`: name of the Availability Zone<br>- `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)<br>- `vpc_subnet`: key of the VPC and subnet connected by '-' character<br>- `security_group`: security group assigned to ENI used by VM<br>- `type`: EC2 type VM<br><br>Example:<pre>spoke_vms = {<br>  "app1_vm01" = {<br>    az             = "eu-central-1a"<br>    vpc            = "app1_vpc"<br>    vpc_subnet     = "app1_vpc-app1_vm"<br>    security_group = "app1_vm"<br>    type           = "t3.micro"<br>  }<br>}</pre> | <pre>map(object({<br>    az             = string<br>    vpc            = string<br>    vpc_subnet     = string<br>    security_group = string<br>    type           = string<br>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr`: CIDR for VPC<br>- `nacls`: map of network ACLs<br>- `security_groups`: map of security groups<br>- `subnets`: map of subnets with properties:<br>   - `az`: availability zone<br>   - `set`: internal identifier referenced by main.tf<br>   - `nacl`: key of NACL (can be null)<br>- `routes`: map of routes with properties:<br>   - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`<br>   - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br>   - `next_hop_type` - internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br><br>Example:<pre>vpcs = {<br>  example_vpc = {<br>    name = "example-spoke-vpc"<br>    cidr = "10.104.0.0/16"<br>    nacls = {<br>      trusted_path_monitoring = {<br>        name               = "trusted-path-monitoring"<br>        rules = {<br>          allow_inbound = {<br>            rule_number = 300<br>            egress      = false<br>            protocol    = "-1"<br>            rule_action = "allow"<br>            cidr_block  = "0.0.0.0/0"<br>            from_port   = null<br>            to_port     = null<br>          }<br>        }<br>      }<br>    }<br>    security_groups = {<br>      example_vm = {<br>        name = "example_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>        }<br>      }<br>    }<br>    subnets = {<br>      "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }<br>      "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }<br>    }<br>    routes = {<br>      vm_default = {<br>        vpc_subnet    = "app1_vpc-app1_vm"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1"<br>        next_hop_type = "transit_gateway_attachment"<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr = string<br>    nacls = map(object({<br>      name = string<br>      rules = map(object({<br>        rule_number = number<br>        egress      = bool<br>        protocol    = string<br>        rule_action = string<br>        cidr_block  = string<br>        from_port   = string<br>        to_port     = string<br>      }))<br>    }))<br>    security_groups = any<br>    subnets = map(object({<br>      az   = string<br>      set  = string<br>      nacl = string<br>    }))<br>    routes = map(object({<br>      vpc_subnet    = string<br>      to_cidr       = string<br>      next_hop_key  = string<br>      next_hop_type = string<br>    }))<br>  }))</pre> | `{}` | no |

### 2.10.6. Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_load_balancers"></a> [application\_load\_balancers](#output\_application\_load\_balancers) | FQDNs of Application Load Balancers |
| <a name="output_cloudngfws"></a> [cloudngfws](#output\_cloudngfws) | n/a |
| <a name="output_network_load_balancers"></a> [network\_load\_balancers](#output\_network\_load\_balancers) | FQDNs of Network Load Balancers. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->