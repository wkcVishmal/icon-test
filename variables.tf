#Azure authentication variables
# variable "azure-subscription-id" {
#   type = string
#   description = "Azure Subscription ID"
# }
# variable "azure-client-id" {
#   type = string
#   description = "Azure Client ID"
# }
# variable "azure-client-secret" {
#   type = string
#   description = "Azure Client Secret"
# }
# variable "azure-tenant-id" {
#   type = string
#   description = "Azure Tenant ID"
# }

# azure region
variable "location" {
  type        = string
  description = "Azure region where the resource group will be created"
  default     = "north europe"
}

#Network variables
variable "network-vnet-cidr" {
  type        = string
  description = "The CIDR of the network VNET"
}
variable "vm-subnet-cidr" {
  type        = string
  description = "The CIDR for the vm subnet"
}

## Windows VM - Variables# Windows VM Admin User
variable "windows-admin-username" {
  type        = string
  description = "Windows VM Admin User"
  default     = "tfadmin"
}# Windows VM Admin Password
variable "windows-admin-password" {
  type        = string
  description = "Windows VM Admin Password"
  default     = "S3cr3ts24"
}# Windows VM Hostname (limited to 15 characters long)
variable "windows-vm-hostname" {
  type        = string
  description = "Windows VM Hostname"
  default     = "tfazurevm"
}# Windows VM Virtual Machine Size
variable "windows-vm-size" {
  type        = string
  description = "Windows VM Size"
  default     = "Standard_B1s"
}

## OS Image# Windows Server 2019 SKU used to build VMs
variable "windows-2019-sku" {
  type        = string
  description = "Windows Server 2019 SKU used to build VMs"
  default     = "2019-Datacenter"
}
# Windows Server 2016 SKU used to build VMs
variable "windows-2016-sku" {
  type        = string
  description = "Windows Server 2016 SKU used to build VMs"
  default     = "2016-Datacenter"
}
# Windows Server 2012 R2 SKU used to build VMs
variable "windows-2012-sku" {
  type        = string
  description = "Windows Server 2012 R2 SKU used to build VMs"
  default     = "2012-R2-Datacenter"
}