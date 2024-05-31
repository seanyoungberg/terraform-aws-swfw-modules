# 1. AWS Cloud NGFW Lab

## 1.1. Introduction

This repository and associated code is intended for a specific lab scenario for learning. Nothing here should be referenced or intended for production use.

## 1.2. Navigation

### 1.2.1. Outline

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

### 1.2.2. TOC

- [1. AWS Cloud NGFW Lab](#1-aws-cloud-ngfw-lab)
  - [1.1. Introduction](#11-introduction)
  - [1.2. Navigation](#12-navigation)
    - [1.2.1. Outline](#121-outline)
    - [1.2.2. TOC](#122-toc)
- [2. Lab Session 1](#2-lab-session-1)
  - [2.1. Topology](#21-topology)
  - [2.2. Initialize Qwiklab](#22-initialize-qwiklab)
  - [2.3. Local Execution Notes](#23-local-execution-notes)
  - [2.4. Update IAM Policies](#24-update-iam-policies)
  - [2.5. Check Marketplace Subscriptions](#25-check-marketplace-subscriptions)
  - [2.6. Setup Cloud9 IDE Environment](#26-setup-cloud9-ide-environment)
  - [2.7. Create IAM role for programmatic access](#27-create-iam-role-for-programmatic-access)
  - [2.10. Manually Onboard Qwiklabs Account](#210-manually-onboard-qwiklabs-account)
  - [2.11. Deploy AWS Infrastructure and Cloud NGFW Isolated Model](#211-deploy-aws-infrastructure-and-cloud-ngfw-isolated-model)
  - [Enable CloudWatch Metrics](#enable-cloudwatch-metrics)
  - [Enable CloudWatch Logs](#enable-cloudwatch-logs)
  - [2.11. Create Outbound Policies for App1 in Cloud NGFW Console](#211-create-outbound-policies-for-app1-in-cloud-ngfw-console)
  - [Create Outbound Policies for App2 with terraform](#create-outbound-policies-for-app2-with-terraform)
  - [C](#c)



# 2. Lab Session 1

During this session you will:

- Initialize Qwiklabs (QL) environment. Each will have their own on-demand AWS account that will be active throghout the workshop
- Access existing Cloud NGFW tenant console
- Access Cloud9 AWS IDE environment
- Create IAM role for programmatic access inside QL AWS account
- Onboard QL AWS account to existing Cloud NGFW tenant
- Deploy prepared terraform to create 
  
## 2.1. Topology

For this section, we will be deploying the isolated model and managing it via the native Cloud NGFW contructs.

- Same Firewall Cluster(s) to inspect applications in multiple VPCs.
- Transparently insert inspection in your application VPCs for both Ingress and Egress Traffic.
- No TGW resource is required.
- E/W Inspection not supported for this model

![image](https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules/assets/9754982/a1b04cd9-2324-4488-a104-34fdb15e4254)



## 2.2. Initialize Qwiklab

- Access [QwikLabs](https://paloaltonetworks.qwiklabs.com/) and create an account using PANW email or login with existing account
- Start Lab from the Qwiklabs Classroom. It will take a few minutes to provision
- Click Open Console and authenticate to AWS account with credentials displayed in Qwiklabs
- Check Top Right menu to verify you are in the us-west-2 (Oregon) Region

  
## 2.3. Local Execution Notes

This lab guide is designed for using the AWS Cloud9 IDE environment for git, editing files, and executing terraform. The Cloud9 environment will assume your AWS console user permissions. If you are familiar with these tools and prefer to run locally, you will need to need to copy the static IAM keys from QwikLabs console and use them in your local credentials. Some of the other steps throughout this guide will need to be modified if running locally.

There are various way to do this, but one example is:

```
aws configure --profile qwiklabs
AWS Access Key ID [None]: *****EXAMPLEACCESSKEY
AWS Secret Access Key [None]: ************************EXAMPLESECRETKEY
Default region name [None]: us-west-2
Default output format [None]: json
```

When executing terraform, you will need to reference profile `qwiklabs` in your tfvars that will be passed to the provider block.


## 2.4. Update IAM Policies


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

## 2.5. Check Marketplace Subscriptions

> &#8505; Before you can launch Panorama images in an account, the account must first have accepted the Marketplace License agreement for that product.

> &#8505; The QwikLabs accounts should already be subscribed to these offers, but we will need to verify and correct if required.

- Search for `AWS Marketplace Subscriptions` in top search bar
- Verify that there is an active subscription for:
  - `Palo Alto Networks Panorama`

<img src="https://user-images.githubusercontent.com/43679669/210279563-6e313499-41fb-42b3-b516-636df544c6e6.gif" width=50% height=50%>

- If you have the Panorama subscription, continue to the next section
- If you are missing either subscription, select `Discover Products` and search for `palo alto`
- Select `Palo Alto Networks Panorama` as needed
- Continue to Subscribe
- Accept Terms
- Allow a few moments for the Subscription to be processed
- Repeat for the other Subscription if needed
- Exit out of the Marketplace
- Notify lab instructor if you have any issues

---

## 2.6. Setup Cloud9 IDE Environment

- Copy Cloud9 URL from QwikLabs
  - Alternatively, search for Cloud9 in AWS Console
- Once inside the environment, we need to adjust a setting for IAM to work
  - Cloud9 Icon in top left -> Preferences
  - AWS Settings
  - Disable `AWS managed temporary credentials`
---

- Run below command from Cloud9 terminal. It will:
  - Clone the repository that contains the code and resources for this lab
  - Execute a shell script to install terraform in the Cloud9 envitonment


```cd ~/environment && git clone https://github.com/seanyoungberg/terraform-aws-swfw-modules.git && chmod +x ~/environment/terraform-aws-swfw-modules/deployments/install_terraform.sh && ~/environment/terraform-aws-swfw-modules/deployments/install_terraform.sh```


> &#8505; Terraform projects often have version constraints in the code to protect against potentially breaking syntax changes when new version is released. For this project, the [version constraint](https://github.com/PaloAltoNetworks/lab-aws-gwlb-vmseries/blob/main/terraform/vmseries/versions.tf) is:
> ```
> terraform {
>  required_version = ">=0.12.29, <2.0"
>}
>```
>
>Terraform is distributed as a single binary so isn't usually managed by OS package managers. It simply needs to be downloaded and put into a system `$PATH` location. In this case ~/bin/terraform.

---

## 2.7. Create IAM role for programmatic access

Before we can deploy Cloud NGFW resources with Terraform, we must first create a role in AWS.

You will authenticate against your Cloud NGFW by assuming roles in your AWS account that are allowed to make API calls to the AWS API Gateway service. The associated tags with the roles dictate the type of Cloud NGFW programmatic access granted — Firewall Admin, RuleStack Admin, or Global Rulestack Admin.

`cd ~/environment/terraform-aws-swfw-modules/deployments/iam_roles_cloudngfw/`

`cp example.tfvars terraform.tfvars`

`terraform init`

`terraform apply`

## 2.10. Manually Onboard Qwiklabs Account

- Navigate to the [Cloud NGFW web console](https://web.aws.cloudngfw.paloaltonetworks.com/)
- Authenticate with PANW SSO
- Settings -> AWS Accounts -> Add AWS Account
- Enter Account ID -> Download Cloud Formation Template
- Create Cloud Formation Stack with downloaded template in QwikLabs AWS account
- Enter a name for the stack
- Enter TrustedAccount ID and ExternalID from Cloud NGFW Console
  - Use `Check Details` on the AWS Accounts section
- Other Parameters should remain with default values
- Deploy Stack and ensure it completes successfully

After Stack is complete, we must let Cloud NGFW know the ARN of the cross-account roles that were created.
- In Cloud NGFW console, Use Actions menus on your AWS account to manage cross account roles
- The ARNs of the roles can be found on the Outputs section of the CloudFormation Stack
- Verify Status in Cloud NGFW Console goes to Success

## 2.11. Deploy AWS Infrastructure and Cloud NGFW Isolated Model

During this step, you will deploy a prepared terraform package based on the public module example. It will create the AWS infrastructure as well as utilize the CloudNGFW provider to deploy a Cloud NGFW resource and basic local rulestack.

The initial deployment will be isolated model, where GWLB endpoints are created in each application VPC. All inbound and outboud Internet traffic is directed to endpoints inside the application VPC.

- Same Firewall Cluster(s) to inspect applications in multiple VPCs.
- Transparently insert inspection in your application VPCs for both Ingress and Egress Traffic.
- No TGW resource is required.
- E/W Inspection not supported for this model

![image](https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules/assets/9754982/a1b04cd9-2324-4488-a104-34fdb15e4254)

`cd ~/environment/terraform-aws-swfw-modules/deployments/ql_cloudngfw_isolated_design/`

`cp example.tfvars terraform.tfvars`

- Edit value of `name_prefix` in `terraform.tfvars` to your name or a unique identifier. Make sure to save if you edit in the Cloud9 IDE.

We will all be using the same Cloud NGFW tenant, so need a way to distinguish.

- All other values can stay the same for now

- Deploy infrastructure

`terraform init`
`terraform apply`

Deployment will take around 5 minutes and then another 15 minutes before Cloud NGFW resource is ready.


## Enable CloudWatch Metrics


## Enable CloudWatch Logs



## 2.11. Create Outbound Policies for App1 in Cloud NGFW Console

- Prefix List for Source
- FQDN List for Destination
- App ID Policy


## Create Outbound Policies for App2 with terraform

## C