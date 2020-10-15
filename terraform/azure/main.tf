provider "azurerm" {
  version = "~>2.20.0"
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-azu-e2-DORIS-prod"
    storage_account_name = "dorisappdev"
    container_name       = "terraform-state"
    key                  = "azure-doris-digital-platform-test-default-dev.terraform.tfstate"
  }
}

### Network Resources 
### Managed by DOITT
data "azurerm_resource_group" "rg-network" {
  name = var.azurerm_resource_group_network
}

data "azurerm_resource_group" "rg-non-prd" {
  name = var.azurerm_resource_group_non_prd
}

data "azurerm_resource_group" "rg-prd" {
  name = var.azurerm_resource_group_prd
}

data "azurerm_virtual_network" "vnet" {
  name                = var.azurerm_virtual_network_name
  resource_group_name = var.azurerm_resource_group_network
}

data "azurerm_subnet" "subnet-public-01" {
  name                 = var.azurerm_subnet_public_01
  virtual_network_name = var.azurerm_virtual_network_name
  resource_group_name  = var.azurerm_resource_group_network
}

data "azurerm_subnet" "subnet-public-02" {
  name                 = var.azurerm_subnet_public_02
  virtual_network_name = var.azurerm_virtual_network_name
  resource_group_name  = var.azurerm_resource_group_network
}

data "azurerm_subnet" "subnet-private-01" {
  name                 = var.azurerm_subnet_private_01
  virtual_network_name = var.azurerm_virtual_network_name
  resource_group_name  = var.azurerm_resource_group_network
}

data "azurerm_subnet" "subnet-private-02" {
  name                 = var.azurerm_subnet_private_02
  virtual_network_name = var.azurerm_virtual_network_name
  resource_group_name  = var.azurerm_resource_group_network
}

data "azurerm_network_security_group" "nsg" {
  name                = var.azurerm_virtual_network_security_group_name
  resource_group_name = data.azurerm_resource_group.rg-network.name
}

resource "azurerm_network_security_rule" "example" {
  name                                       = "test123"
  priority                                   = 100
  direction                                  = "Outbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "*"
  source_address_prefix                      = "*"
  destination_address_prefix                 = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.example.id]
  resource_group_name                        = data.azurerm_resource_group.rg-network.name
  network_security_group_name                = data.azurerm_network_security_group.nsg.name
}

### ASG
resource "azurerm_application_security_group" "example" {
  name                = "tf-appsecuritygroup"
  location            = data.azurerm_resource_group.rg-network.location
  resource_group_name = data.azurerm_resource_group.rg-network.name

  tags = var.tags
}

### VM Images
data "azurerm_platform_image" "centos" {
  location  = data.azurerm_resource_group.rg-network.location
  publisher = "OpenLogic"
  offer     = "CentOS"
  sku       = "7.5"
  # version   = "latest"
}


### Storage VM
resource "azurerm_network_interface" "storage-nic" {
  name                = "${var.prefix}-storage-nic"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.subnet-public-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "storage-osdisk" {
  name                = "storage-osdisk"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = data.azurerm_platform_image.centos.id
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "storage" {
  name                  = "${var.prefix}-storage"
  location              = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name   = data.azurerm_resource_group.rg-non-prd.name
  network_interface_ids = [azurerm_network_interface.storage-nic.id]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "storage-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = azurerm_managed_disk.storage-osdisk.id
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags = var.tags
}

### Hyku App VM 
resource "azurerm_network_interface" "hyku-nic" {
  name                = "${var.prefix}-hyku-nic"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.subnet-public-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "example-hyku-nic" {
  network_interface_id          = azurerm_network_interface.hyku-nic.id
  application_security_group_id = azurerm_application_security_group.example.id
}

resource "azurerm_managed_disk" "hyku-osdisk" {
  name                = "hyku-osdisk"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = data.azurerm_platform_image.centos.id
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "hyku" {
  name                  = "${var.prefix}-hyku"
  location              = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name   = data.azurerm_resource_group.rg-non-prd.name
  network_interface_ids = [azurerm_network_interface.hyku-nic.id]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "hyku-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = azurerm_managed_disk.hyku-osdisk.id
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags = var.tags
}

### Archivematica VM
resource "azurerm_network_interface" "archivematica-nic" {
  name                = "${var.prefix}-archivematica-nic"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.subnet-public-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "archivematica-osdisk" {
  name                = "archivematica-osdisk"
  location            = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name = data.azurerm_resource_group.rg-non-prd.name

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = data.azurerm_platform_image.centos.id
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "archivematica" {
  name                  = "${var.prefix}-archivematica"
  location              = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name   = data.azurerm_resource_group.rg-non-prd.name
  network_interface_ids = [azurerm_network_interface.archivematica-nic.id]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "archivematica-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = azurerm_managed_disk.archivematica-osdisk.id
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags = var.tags
}

### Storage creation
resource "azurerm_storage_account" "thelma-poc-assets-storage-acct" {
  name                     = "thelmapocassets"
  location                 = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name      = data.azurerm_resource_group.rg-non-prd.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "thelma-poc-assets" {
  name                  = "thelmapocassets"
  storage_account_name  = azurerm_storage_account.thelma-poc-assets-storage-acct.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "thelma-poc-uploads-storage-acct" {
  name                     = "thelmapocuploads"
  location                 = data.azurerm_resource_group.rg-non-prd.location
  resource_group_name      = data.azurerm_resource_group.rg-non-prd.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "thelma-poc-uploads" {
  name                  = "thelmapocuploads"
  storage_account_name  = azurerm_storage_account.thelma-poc-uploads-storage-acct.name
  container_access_type = "private"
}

### Outputs
output "storage_ip_address" {
  value = azurerm_network_interface.storage-nic.private_ip_address
}

output "hyku_ip_address" {
  value = azurerm_network_interface.hyku-nic.private_ip_address
}

output "archivematica_ip_address" {
  value = azurerm_network_interface.archivematica-nic.private_ip_address
}

