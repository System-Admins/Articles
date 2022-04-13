// This is the parameter section.
param location string = resourceGroup().location

// This is the variable section.
var adminUsername = 'systemadmin'
var adminPassword = 'MySuperSecretPassword123!'
var publicIpName = 'pip-p-01'
var publicIpAllocation = 'Dynamic'
var publicIpSku = 'Basic'
var publicIpDomainNameLabel = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
var vmOsVersion = '2019-datacenter-gensecond'
var vmSize = 'Standard_D2s_v3'
var vmName = 'vm-p-01'
var vmNic = 'nic-p-01'
var vnet = 'vnet-p-01'
var vnetSubnet = 'snet-p-01'
var vnetSpace = '10.0.0.0/16'
var vnetSubnetPrefix = '10.0.0.0/24'
var nsg = 'nsg-p-01'
var storageAccount = 'stp01'
var storageAccountSku = 'Standard_LRS'

// Creates the storage acccount.
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccount
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'Storage'
}

// Creates the public ip.
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAllocation
    dnsSettings: {
      domainNameLabel: publicIpDomainNameLabel
    }
  }
}

// Creates the network security group (NSG).
resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsg
  location: location
  properties: {
    securityRules: [
      // Allow inbound RDP.
      {
        name: 'inbound-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Creates the virtual network (VNet).
resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpace
      ]
    }
    subnets: [
      {
        name: vnetSubnet
        properties: {
          addressPrefix: vnetSubnetPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

// Creates the network interface card (NIC).
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vmNic
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, vnetSubnet)
          }
        }
      }
    ]
  }
}

// Creates the virtual machine.
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: vmOsVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 200
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}
