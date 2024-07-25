terraform {
  required_version = ">= 1.3.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
    cloudngfwaws = {
      source  = "PaloAltoNetworks/cloudngfwaws"
      version = "2.0.10"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
    scm = {
      source  = "paloaltonetworks/scm"
      version = "0.9.2"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_credentials_profile
}


provider "cloudngfwaws" {
  region    = var.region
  profile   = var.aws_credentials_profile
  host      = "api.${var.region}.aws.cloudngfw.paloaltonetworks.com"
  lfa_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.provider_role}"
  lra_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.provider_role}"
  sync_mode = true
}

provider "time" {}

provider "scm" {
  host          = "api.strata.paloaltonetworks.com"
  client_id     = "scm-terraform@1561638640.iam.panserviceaccount.com"
  client_secret = "7ccdd6f5-bde1-4a7f-ac3a-36e64c51bbe3"
  scope         = "tsg_id:1561638640"
}