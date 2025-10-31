#######################
# RESOURCE GROUP
#######################
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

#######################
# NETWORKING
#######################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_bastion_cidr]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_app_cidr]
  default_outbound_access_enabled = false
}

######## Security Group
# Security Group - App - subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.project_name}-app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-from-Bastion"
    priority                   = 100
    direction                  = "Inbound" 
    access                     = "Allow"
    protocol                   = "*" 
    source_port_range          = "*"
    destination_port_ranges     = ["22", "3389"]
    source_address_prefix      = azurerm_subnet.bastion.address_prefixes[0]
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow ingress to resources inside VNet"
  }
  security_rule {
    name                       = "Allow-to-http-app"
    priority                   = 110
    direction                  = "Inbound" 
    access                     = "Allow"
    protocol                   = "Tcp" 
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Allow ingress to VM:80 inside VNet"
  }
  security_rule {
    name                       = "Deny-other-ingress-traffic"
    priority                   = 1000
    direction                  = "Inbound" 
    access                     = "Deny"
    protocol                   = "*" 
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny others ingress to VNet"
  }

  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

#######################
# BASTION
#######################
resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.project_name}-bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project_name}-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

#######################
# VIRTUAL MACHINE
#######################
resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_count
  name                = "${var.project_name}-vm-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

resource "azurerm_linux_virtual_machine" "VMs" {
  count               = var.vm_count
  name                = "${var.project_name}-vm-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "20.04.202502181"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = true

  tags = {
    Project = var.project_name
    Owner   = var.owner
  }
}

# Install Nginx to VM
resource "azurerm_virtual_machine_extension" "vm_nginx" {
  count                = var.vm_count
  name                 = "Nginx"
  virtual_machine_id   = azurerm_linux_virtual_machine.VMs[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    commandToExecute = "sudo apt-get update && sudo apt-get install -y nginx && echo \"Hello World from $(hostname)\" | sudo tee /var/www/html/index.html && sudo systemctl restart nginx"
  })
}

#####################
# Load Balancer
#####################
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.project_name}-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = "${var.project_name}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool"
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-probe"
  port            = 80
}

resource "azurerm_lb_rule" "example_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend.id]
}

resource "azurerm_lb_outbound_rule" "lb_outbound_rule" {
  name                    = "lb-outbound-rule"
  loadbalancer_id         = azurerm_lb.lb.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

# Backend pool association
resource "azurerm_network_interface_backend_address_pool_association" "vm_nic_assctn" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
}