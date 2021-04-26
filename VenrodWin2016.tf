# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "Venrod3hrsWin2016" {
    name     = "Venrod3hrsWin2016"
    location = "eastus2"

    tags = {
        environment = "Venrod Terraform WindowsVM "
    }
}

# Create virtual network
resource "azurerm_virtual_network" "Venrod3hrsWin2016network" {
    name                = "Venrod3hrsWin2016network"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Venrod3hrsWin2016.name

    tags = {
        environment = "Venrod Terraform WinVM"
    }
}

# Create subnet
resource "azurerm_subnet" "Venrod3hrsWin2016subnet" {
    name                 = "Venrod3hrsWin2016Subnet"
    resource_group_name  = azurerm_resource_group.Venrod3hrsWin2016.name
    virtual_network_name = azurerm_virtual_network.Venrod3hrsWin2016network.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "Venrod3hrsWin2016publicip" {
    name                         = "Venrod3hrsWin2016PublicIP"
    location                     = "eastus2"
    resource_group_name          = azurerm_resource_group.Venrod3hrsWin2016.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Venrod Terraform WinVM"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Venrod3hrsWin2016nsg" {
    name                = "Venrod3hrsWin2016NetworkSecurityGroup"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Venrod3hrsWin2016.name

    security_rule {
        name                       = "RDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
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
        environment = "Venrod Terraform WinVM"
    }
}

# Create network interface
resource "azurerm_network_interface" "Venrod3hrsWin2016nic" {
    name                      = "Venrod3hrsWin2016Nic"
    location                  = "eastus2"
    resource_group_name       = azurerm_resource_group.Venrod3hrsWin2016.name

    ip_configuration {
        name                          = "Venrod3hrswin2016NicConfiguration"
        subnet_id                     = azurerm_subnet.Venrod3hrsWin2016subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.Venrod3hrsWin2016publicip.id
    }

    tags = {
        environment = "Venrod Terraform WinVM"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Venrod3hrsWin2016nsg" {
    network_interface_id      = azurerm_network_interface.Venrod3hrsWin2016nic.id
    network_security_group_id = azurerm_network_security_group.Venrod3hrsWin2016nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.Venrod3hrsWin2016.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Venrod3hrsWin2016storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.Venrod3hrsWin2016.name
    location                    = "eastus2"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Venrod Terraform WinVM"
    }
}

# Create (and display) an SSH key  (Uncomment this if you wish to use SSH keys)
#resource "tls_private_key" "example_ssh" {
#  algorithm = "RSA"
#  rsa_bits = 4096
#}
#output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_windows_virtual_machine" "Venrod3hrswin2016vm" {
    name                  = "Venrod3hrsWin2016VM"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.Venrod3hrsWin2016.name
    network_interface_ids = [azurerm_network_interface.Venrod3hrsWin2016nic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "Venrod3hrsOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2016-Datacenter"
        version = "latest"
    }

    computer_name  = "VenrodmyWinvm"
    admin_username = "cloud1ph"
#    disable_password_authentication = false
        admin_password = "N0virus1!"

#    admin_ssh_key { (Uncomment this if you wish to use SSH keys)
#        username       = "cloud1ph"
#       public_key     = tls_private_key.example_ssh.public_key_openssh
#    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.Venrod3hrsWin2016storageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Venrod Terraform WinVM"
    }
}

# Uncomment this section if you wish to install DS agent and add it on TMCS cloud one console

#resource "azurerm_virtual_machine_extension" "Venrod3hrswin2016vm" {
#  name                 = "Venrod3hrswin2016vm"
#  virtual_machine_id   = azurerm_windows_virtual_machine.Venrod3hrswin2016vm.id
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.1"

#  settings = <<SETTINGS
#    {
#	"fileUris": ["https://raw.githubusercontent.com/Cloud1PH/Public-Raw-Scripts/AgentDeploymentScriptWindows/windows.ps1"],
#    "commandToExecute": "powershell.exe windows.ps1"
#    }
#SETTINGS


# tags = {
#    environment = "Venrod Terraform WinVM"
#  }
#}
