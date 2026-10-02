param location string = 'eastus'
param adminUsername string = 'azureuser'

@secure()
param adminPassword string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
    name: 'nsg-1'
    location: location
    properties: {
        securityRules: [
            {
                name: 'Allow-SSH' 
                properties: {
                    priority: 1000
                    direction: 'Inbound'
                    access: 'Allow'
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    destinationPortRange: '22'
                    sourceAddressPrefix: '*'
                    destinationAddressPrefix: '*'
                
                }
            }
        ]
    }  
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
    name: 'vnet-1'
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                '10.0.0.0/26'
            ]
        } 
        subnets: [
            {
                name: 'subnet-infra'
                properties: {
                    addressPrefix: '10.0.1.0/24'
                    networkSecurityGroup: {
                        id: nsg.id
                    }
                }
            }
        ]
    }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
    name: 'pip-mv-1'
    location: location
    properties:{
        publicIPAllocationMethod: 'Dynamic'
    }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
    name: 'nic-mv-1'
    location:location
    properties: {
        ipConfigurations: [
            {
                name: 'ipconfig1'
                properties: {
                    privateIPAllocationMethod: 'Dynamic'
                    publicIPAddress: {
                        id: publicIP.id
                    }
                    subnet: {
                        id: vnet.properties.subnets[0].id
                    }
                }
            }
        ]
    }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
    name: 'vm-linux-1d'
    location:location
    properties: {
        hardwareProfile: {
            vmSize:'Standard_B1s' 
        }
        osProfile: {
            computerName:'vmlinux'
            adminUsername: adminUsername
            adminPassword: adminPassword

        }
        storageProfile: {
            imageReference: {
                publisher: 'Canonical'
                offer: '0001-com-ubuntu-server-jammy'
                sku: '22_04-lts'
                version: 'lastest'
            
            }
            osDisk: {
                createOption: 'FromImage'
                managedDisk: {
                    storageAccountType: 'Standard_LRS'
                }
            }
        }
        networkProfile: {
            networkInterfaces: [
                {
                    id: nic.id
                }
            ]
        }
    }
}
