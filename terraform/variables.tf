# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "azurerm_resource_group_network" {
  description = "Name for Network Resource Group (DoITT Managed)"
}

variable "azurerm_resource_group_non_prd" {
  description = "Name for Non-PRD Resource Group (DoITT Managed)"
}

variable "azurerm_resource_group_prd" {
  description = "Name for PRD Resource Group (DoITT Managed)"
}

variable "azurerm_virtual_network_name" {
  description = "Name for Azure Vnet (DoITT Managed)"
}

variable "azurerm_virtual_network_security_group_name" {
  description = "Name for Azure NSG (DoITT Managed)"
}

variable "azurerm_subnet_public_01" {
  description = "Name for Azure Subnet - Public01 (DoITT Managed)"
}

variable "azurerm_subnet_public_02" {
  description = "Name for Azure Subnet - Public02 (DoITT Managed)"
}

variable "azurerm_subnet_private_01" {
  description = "Name for Azure Subnet - Private01 (DoITT Managed)"
}

variable "azurerm_subnet_private_02" {
  description = "Name for Azure Subnet - Private02 (DoITT Managed)"
}

variable "remote_state_hostname" {
  description = "Hostname for remote state storage"
}

variable "remote_state_organization" {
  description = "Organization for remote state"
}

variable "remote_state_workspace_name" {
  description = "Workspace Name for remote state"
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
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The base domain name used for all URLs"
  default     = "getinfo.nyc"
}

variable "prefix" {
  description = "Prefix for resource names"
  default = "thelmapoc"
}

