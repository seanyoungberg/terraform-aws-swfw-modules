terraform {
  required_version = ">= 1.3.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  #profile = "qwiklabs"
}

resource "aws_iam_role" "ngfw_role" {
  name = "CloudNGFWRole"

  inline_policy {
    name = "apigateway_policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "execute-api:Invoke",
            "execute-api:ManageConnections"
          ],
          "Resource" : "arn:aws:execute-api:*:*:*"
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${var.provider_account}:user/awsstudent"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    CloudNGFWRulestackAdmin       = "Yes"
    CloudNGFWFirewallAdmin        = "Yes"
    CloudNGFWGlobalRulestackAdmin = "Yes"
  }
}
