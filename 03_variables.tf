# variables.tf
variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "owner" {
  description = "Person who creates the resources in AZURE"
  type        = string
}

variable "project_name" {
  description = "Project tag/name prefix"
  type        = string
  default     = "cloudforge"
}

variable "vnet_cidr" {
  description = "VNet CIDR"
  type        = string
  default     = "10.42.0.0/16"
}

variable "subnet_app_cidr" {
  description = "App subnet CIDR"
  type        = string
  default     = "10.42.1.0/24"
}

# Must be /26 or larger, and named exactly AzureBastionSubnet
variable "subnet_bastion_cidr" {
  description = "AzureBastionSubnet CIDR (must be /26 or larger)"
  type        = string
  default     = "10.42.0.0/26"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Linux admin username"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Your SSH public key (~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}
