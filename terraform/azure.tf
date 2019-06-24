provider "azurerm" {
  skip_provider_registration = true
}

variable "prefix" {
  default = "doris"
}

data "azurerm_resource_group" "rg" {
  name = "${var.azurerm_resource_group_name}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-web"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8000"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = "${azurerm_subnet.subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_public_ip" "storage-pip" {
  name                = "${var.prefix}-storage-pip"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "storage-nic" {
  name                = "${var.prefix}-storage-nic"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.storage-pip.id}"
  }
}

data "azurerm_platform_image" "centos" {
  location  = "${data.azurerm_resource_group.rg.location}"
  publisher = "OpenLogic"
  offer     = "CentOS"
  sku       = "7.5"

  # version   = "latest"
}

resource "azurerm_managed_disk" "storage-osdisk" {
  name                = "storage-osdisk"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = "${data.azurerm_platform_image.centos.id}"
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "storage" {
  name                  = "${var.prefix}-storage"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.storage-nic.id}"]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "storage-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = "${azurerm_managed_disk.storage-osdisk.id}"
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags {
    storage = "storage-1"
  }
}

data "azurerm_public_ip" "data-storage-pip" {
  name                = "${azurerm_public_ip.storage-pip.name}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.storage"]
}

resource "azurerm_public_ip" "hyku-pip" {
  name                = "${var.prefix}-hyku-pip"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "hyku-nic" {
  name                = "${var.prefix}-hyku-nic"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hyku-pip.id}"
  }
}

resource "azurerm_managed_disk" "hyku-osdisk" {
  name                = "hyku-osdisk"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = "${data.azurerm_platform_image.centos.id}"
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "hyku" {
  name                  = "${var.prefix}-hyku"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hyku-nic.id}"]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "hyku-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = "${azurerm_managed_disk.hyku-osdisk.id}"
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags {
    hyku = "hyku-1"
  }
}

data "azurerm_public_ip" "data-hyku-pip" {
  name                = "${azurerm_public_ip.hyku-pip.name}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.hyku"]
}

resource "azurerm_public_ip" "archivematica-pip" {
  name                = "${var.prefix}-archivematica-pip"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "archivematica-nic" {
  name                = "${var.prefix}-archivematica-nic"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.archivematica-pip.id}"
  }
}

resource "azurerm_managed_disk" "archivematica-osdisk" {
  name                = "archivematica-osdisk"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  #os_type              = "linux"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"

  #source_uri           = ""
  image_reference_id = "${data.azurerm_platform_image.centos.id}"
  disk_size_gb       = "1000"
}

resource "azurerm_virtual_machine" "archivematica" {
  name                  = "${var.prefix}-archivematica"
  location              = "${data.azurerm_resource_group.rg.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.archivematica-nic.id}"]
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "archivematica-osdisk"

    # if this is provided, os_profile is not allowed
    os_type           = "linux"
    managed_disk_id   = "${azurerm_managed_disk.archivematica-osdisk.id}"
    managed_disk_type = "Premium_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  tags {
    archivematica = "archivematica-1"
  }
}

data "azurerm_public_ip" "data-archivematica-pip" {
  name                = "${azurerm_public_ip.archivematica-pip.name}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.archivematica"]
}

### Storage creation
resource "azurerm_storage_account" "doris-services-assets" {
  name                     = "dorisservicesassets"
  resource_group_name      = "${data.azurerm_resource_group.rg.name}"
  location                 = "${data.azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "doris-services-assets" {
  name                  = "dorisservicesassets"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.doris-services-assets.name}"
  container_access_type = "container"
}

resource "azurerm_storage_account" "doris-services-uploads" {
  name                     = "dorisservicesuploads"
  resource_group_name      = "${data.azurerm_resource_group.rg.name}"
  location                 = "${data.azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "doris-services-uploads" {
  name                  = "dorisservicesuploads"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.doris-services-uploads.name}"
  container_access_type = "container"
}

### Output part

output "public_storage_ip_address" {
  value = "${data.azurerm_public_ip.data-storage-pip.ip_address}"
}

output "public_hyku_ip_address" {
  value = "${data.azurerm_public_ip.data-hyku-pip.ip_address}"
}

output "public_archivematica_ip_address" {
  value = "${data.azurerm_public_ip.data-archivematica-pip.ip_address}"
}
