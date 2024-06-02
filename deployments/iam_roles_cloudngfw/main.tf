### Get Account ID

data "aws_caller_identity" "current" {}

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
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/awsstudent"
          ]
        },
        "Action" : "sts:AssumeRole"
      },
      {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSCloud9SSMAccessRole"
          },
          "Action": "sts:AssumeRole"
      }
    ]
  })

  tags = {
    CloudNGFWRulestackAdmin       = "Yes"
    CloudNGFWFirewallAdmin        = "Yes"
    CloudNGFWGlobalRulestackAdmin = "Yes"
  }
}
