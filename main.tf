# Create a resource group for network
resource "azurerm_resource_group" "resource_group" {
  name     = "resource-group-${terraform.workspace}"
  location = var.location
}
# Create the network VNET
resource "azurerm_virtual_network" "network-vnet" {
  name                = "network-vnet-${terraform.workspace}"
  address_space       = [var.network-vnet-cidr]
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
}
# Create a subnet for VM
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet-${terraform.workspace}"
  address_prefixes     = [var.vm-subnet-cidr]
  virtual_network_name = azurerm_virtual_network.network-vnet.name
  resource_group_name  = azurerm_resource_group.resource_group.name
}

# Bootstrapping Script
data "template_file" "tf-script" {
  template = file("setup.ps1")
}
# Create Network Security Group to Access VM from Internet
resource "azurerm_network_security_group" "native-app-nsg" {
  name                = "native-app-nsg-${terraform.workspace}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  security_rule {
    name                       = "AllowRDP"
    description                = "Allow RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*" 
  }
  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*" 
  }
  security_rule {
    name                       = "AllowHTTPS"
    description                = "Allow HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*" 
  }
}
# Associate the NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "native-nsg-association" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.native-app-nsg.id
}
# Create Windows Virtual Machine Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "native-ss" {
  name                = "native-ss-${terraform.workspace}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku        = var.windows-vm-size
  instances  = 2
  computer_name_prefix  = var.windows-vm-hostname
  admin_username        = var.windows-admin-username
  admin_password        = var.windows-admin-password
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows-2019-sku
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  network_interface {
    name    = "${var.windows-vm-hostname}-network"
    primary = true
    ip_configuration {
      name      = "${var.windows-vm-hostname}-internal"
      primary   = true
      subnet_id = azurerm_subnet.vm-subnet.id
    }
  }
  extension {
    name                       = "CustomScript"
    publisher                  = "Microsoft.Compute"
    type                       = "CustomScriptExtension"
    type_handler_version       = "1.10"
    auto_upgrade_minor_version = true
    settings = jsonencode({ "commandToExecute" = "powershell -command \" System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf-script.rendered)}')) | Out-File -filepath setup.ps1\" && powershell -ExecutionPolicy Unrestricted -File setup.ps1" })
    protected_settings = jsonencode({ "managedIdentity" = {} })
  }
}

# App service plan and app service
resource "azurerm_app_service_plan" "app-service-plan" {
  name                = "website-appservice-plan-${terraform.workspace}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku {
    tier = "PremiumV2"
    size = "P2v2"
  }
}

resource "azurerm_app_service" "app-service" {
  name                = "website-${terraform.workspace}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  app_service_plan_id = azurerm_app_service_plan.app-service-plan.id
  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
}

# Storage account & CDN
resource "azurerm_storage_account" "static-web-storage" {
  name                = "icon${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resource_group.name
 
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

# CDN Profile
resource "azurerm_cdn_profile" "static-web-cdn-profile" {
  name                = "icon-cdnprofile-${terraform.workspace}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard_Microsoft"
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "cdn-endpoint" {
  name                = "icon-cdn-endpoint-${terraform.workspace}"
  profile_name        = azurerm_cdn_profile.static-web-cdn-profile.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  origin_host_header = azurerm_storage_account.static-web-storage.primary_web_host

  origin {
    name      = "icon-${terraform.workspace}"
    host_name = azurerm_storage_account.static-web-storage.primary_web_host
  }
}