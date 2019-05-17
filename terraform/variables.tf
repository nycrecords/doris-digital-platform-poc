# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "prefix" {
    description = "Name for all resources created in this module"
}

variable "cidr_range" {
    description = "The CIDR range to use for the VPC"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "key_name" {
  description = "The name of the EC2 Key Pair that can be used to SSH to the EC2 Instances. Leave blank to not associate a Key Pair with the Instances."
  default     = ""
}
variable "aws_region" {
  description = "The AWS region to deploy into"
  default = "us-east-1"
}


variable "domain_name" {
    description = "The base domain name used for all URLs"
    default = "getinfo.nyc"
}
