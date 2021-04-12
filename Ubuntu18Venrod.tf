# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "Venrod8hrsVMUbnt" {
    name     = "Venrod8hrsVMUbnt"
    location = "eastus2"

    tags = {
        environment = "Venrod Terraform LinuxVM Ubnt"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "Venrod8hrsVMUbntnetwork" {
    name                = "Venrod8hrsVMUbntVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Venrod8hrsVMUbnt.name

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Create subnet
resource "azurerm_subnet" "Venrod8hrsVMUbntsubnet" {
    name                 = "Venrod8hrsVMUbntSubnet"
    resource_group_name  = azurerm_resource_group.Venrod8hrsVMUbnt.name
    virtual_network_name = azurerm_virtual_network.Venrod8hrsVMUbntnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "Venrod8hrsVMUbntpublicip" {
    name                         = "Venrod8hrsVMUbntPublicIP"
    location                     = "eastus2"
    resource_group_name          = azurerm_resource_group.Venrod8hrsVMUbnt.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Venrod8hrsVMUbntnsg" {
    name                = "Venrod8hrsVMUbntNetworkSecurityGroup"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Venrod8hrsVMUbnt.name

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
		

    }

    security_rule {
        name                       = "DSA1"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
	
	
   security_rule {
        name                       = "SIEM1"
        priority                   = 103
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "514"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
		
   security_rule {
        name                       = "DSA_Onprem1"
        priority                   = 105
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "4118"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
	

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Create network interface
resource "azurerm_network_interface" "Venrod8hrsVMUbntnic" {
    name                      = "Venrod8hrsVMUbntNIC"
    location                  = "eastus2"
    resource_group_name       = azurerm_resource_group.Venrod8hrsVMUbnt.name

    ip_configuration {
        name                          = "Venrod8hrsVMUbntNicConfiguration"
        subnet_id                     = azurerm_subnet.Venrod8hrsVMUbntsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.Venrod8hrsVMUbntpublicip.id
    }

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Venrod8hrsVMUbntnsg" {
    network_interface_id      = azurerm_network_interface.Venrod8hrsVMUbntnic.id
    network_security_group_id = azurerm_network_security_group.Venrod8hrsVMUbntnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.Venrod8hrsVMUbnt.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Venrod8hrsVMUbntstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.Venrod8hrsVMUbnt.name
    location                    = "eastus2"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Create (and display) an SSH key  (Uncomment this if you wish to use SSH keys)
#resource "tls_private_key" "example_ssh" {
#  algorithm = "RSA"
#  rsa_bits = 4096
#}
#output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "Venrod8hrsVMUbntvm" {
    name                  = "Venrod8hrsVMUbntvm"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.Venrod8hrsVMUbnt.name
    network_interface_ids = [azurerm_network_interface.Venrod8hrsVMUbntnic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "Venrod8hrsVMOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "Venrod8hrsVMUbntvm"
    admin_username = "cloud1ph"
    disable_password_authentication = false
        admin_password = "Ch4ngeMe!"

#    admin_ssh_key { (Uncomment this if you wish to use SSH keys)
#        username       = "cloud1ph"
#       public_key     = tls_private_key.example_ssh.public_key_openssh
#    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.Venrod8hrsVMUbntstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Venrod Terraform LinuxVM"
    }
}

# Uncomment this section if you wish to install DS agent and add it on TMCS cloud one console

resource "azurerm_virtual_machine_extension" "Venrod8hrsVMUbntvm" {
  name                 = "Venrod8hrsVMUbntvm"
  virtual_machine_id   = azurerm_linux_virtual_machine.Venrod8hrsVMUbntvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
	"fileUris": ["https://raw.githubusercontent.com/Cloud1PH/Public-Raw-Scripts/AgentDeploymentScript/linux.sh"],
        "commandToExecute": "sudo ./linux.sh",
	"skipDos2Unix": true
    }
SETTINGS


  tags = {
    environment = "Venrod Terraform LinuxVM"
  }
}