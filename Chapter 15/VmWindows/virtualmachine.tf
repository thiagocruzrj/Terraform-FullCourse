provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-vmwindowsserver"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vmwinserver-vnet"
  address_space       = ["10.0.0.0/16", "192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "vmwinserver-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                    = "vmwinserver-publicip"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "vmwinservertf"
}

resource "azurerm_network_interface" "nic" {
  name                = "vmwinserver-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "externalip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "vmwinserver-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

variable "entryrules" {
  type = map(any)
  default = {
    101 = 80
    102 = 443
    103 = 3389
    102 = 22
  }
}

resource "azurerm_network_security_rule" "rules_free_entry" {
  for_each                    = var.entryrules
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "entry_door_${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}