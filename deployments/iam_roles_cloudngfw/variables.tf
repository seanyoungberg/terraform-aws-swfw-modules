### Provider
variable "provider_account" {
  description = "The AWS Account where the resources should be deployed."
  type        = string
}

variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}

variable "aws_credentials_profile" {
  description = "The named AWS profile to use for authentcation"
  type        = string
  default     = "default"
}