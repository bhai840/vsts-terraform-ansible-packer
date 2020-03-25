terraform {
  required_version = ">= 0.11"

  backend "azurerm" {}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "=2.0.0"
  features {}
  }

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "demo_resource_group" {
  name     = "packerdemocreate"
  location = "South Central US"

  tags = {
    environment = "Packer Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "demo_virtual_network" {
  name                = "packerdemo"
  address_space       = ["10.0.0.0/16"]
  location            =  azurerm_resource_group.demo_resource_group.location
  resource_group_name =  azurerm_resource_group.demo_resource_group.name

  tags = {
    environment = "Packer Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "demo_subnet" {
  name                 = "packerdemo"
  resource_group_name  =  azurerm_resource_group.demo_resource_group.name
  virtual_network_name =  azurerm_virtual_network.demo_virtual_network.name
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "demo_public_ip" {
  name                         = "packerpublicip"
  location                     =  azurerm_resource_group.demo_resource_group.location
  resource_group_name          =  azurerm_resource_group.demo_resource_group.name
  allocation_method            = "Static"
  domain_name_label            = "demopackeriac"

  tags = {
    environment = "Packer Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "demo_security_group" {
  name                = "packersecuritygroups"
  location            =  azurerm_resource_group.demo_resource_group.location
  resource_group_name =  azurerm_resource_group.demo_resource_group.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Packer Demo"
  }
}

resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            =  azurerm_resource_group.demo_resource_group.location
  resource_group_name =  azurerm_resource_group.demo_resource_group.name

  frontend_ip_configuration  {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.demo_public_ip.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name =  azurerm_resource_group.demo_resource_group.name
  loadbalancer_id     =  azurerm_lb.vmss_lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss_probe" {
  resource_group_name = azurerm_resource_group.demo_resource_group.name
  loadbalancer_id     = azurerm_lb.vmss_lb.id
  name                = "ssh-running-probe"
  port                = "8080"
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            =  azurerm_resource_group.demo_resource_group.name
  loadbalancer_id                =  azurerm_lb.vmss_lb.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "8080"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss_probe.id
}

# Generate random text for a unique storage account name
resource "random_id" "storage" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.demo_resource_group.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "demo_storage_account" {
  name                     =  random_id.storage.hex
  resource_group_name      =  azurerm_resource_group.demo_resource_group.name
  location                 =  azurerm_resource_group.demo_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Demo"
  }
}

# Points to Packer build image 
data "azurerm_image" "image" {
  name                =  var.manageddiskname #"demoPackerImage-2020-03-24_04_40_17" #var.manageddiskname
  resource_group_name =  var.manageddiskname_rg
}
output "image_id" {
  value = data.azurerm_image.image.id
}

# Create virtual machine sclae set
resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset"
  location            =  azurerm_resource_group.demo_resource_group.location
  resource_group_name =  azurerm_resource_group.demo_resource_group.name
  upgrade_policy_mode = "Automatic"

  sku {
    name     = "Standard_B2s"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    id = data.azurerm_image.image.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name_prefix = "myazurevm"
    admin_username       = "azureuser"
    admin_password       = "Passwword1234"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfH3QKzCNJUHswZqPD5MpahtHTcsDeFLn9Dyf6fIqPy95BA+3aO9R9YkwrgEHgVGEIjhGghqqIp4Y5y9eclp1Z33WdNgT2PXnStOPFVxaO1nqbYWzhJ83F14XIpiKd3Cgz46AsFAom42ddJByNW2OY/9tRcvJI9klSYE0Vkoh7hSwCer+1ZEH4cmmeJG5CiYW9Nrh4UVdLtHJFn/9sHGW/Gy7D/hZjrMct5XZLnUcQJVsrq7D2ZmGCxWSAdDB3Uy+Y3eJT6+znPvwLt98HqGqSyBugjhsw84dUQv9A8P4rfGYXwR2Ik+ajuD9oXiH9JkB5FOcLEpHwEh9ja9O/Rc9j ubuntu@ip-172-31-31-126"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.demo_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }

  tags = {
    environment = "Terraform Demo"
  }
}

output "vm_ip" {
  value = azurerm_public_ip.demo_public_ip.ip_address
}

output "vm_dns" {
  value = http\n://azurerm_public_ip.demo_public_ip.domain_name_label.SouthCentralUS.cloudapp.azure.com
}
