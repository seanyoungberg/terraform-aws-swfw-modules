### Provider

variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
  default     = "us-west-2"
}

variable "aws_credentials_profile" {
  description = "The named AWS profile to use for authentcation"
  type        = string
  default     = "default"
}