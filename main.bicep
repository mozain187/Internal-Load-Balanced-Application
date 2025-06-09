param location string = resourceGroup().location
param env string = 'web'
param vnetName string = '${env}-Vnet'
param addressPrefix string = '10.0.0.0/16'
param VmsSubnetName string = 'VmsSubnet'
param VmsSubnetPrefix string = '10.0.1.0/24'
param BastionSubnetName string = 'AzureBastionSubnet'
param BastionSubnetPrefix string = '10.0.2.0/24'
param usersSunetName string = 'UsersSubnet'
param usersSubnetPrefix string = '10.0.3.0/24'
param LbSubnetName string = 'LoadBalancerSubnet'
param LbSubnetPrefix string = '10.0.4.0/24'
param adminName string = 'azureUser'
@secure()
param adminPassword string
param LbName string = '${env}-LB'
param storageAccountName string = '${env}diagstorage'
param numOfVMs int = 3

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}


resource webVnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: VmsSubnetName
        properties: {
          addressPrefix: VmsSubnetPrefix
         
        }
      }
      {
        name: BastionSubnetName
        properties: {
          addressPrefix: BastionSubnetPrefix
        }
      }
      {
        name: usersSunetName
        properties: {
          addressPrefix: usersSubnetPrefix
        }
      }
      {
        name: LbSubnetName
        properties: {
          addressPrefix: LbSubnetPrefix
        }
      }
    ]
  }
}



resource availableSet 'Microsoft.Compute/availabilitySets@2024-07-01' = {
  name: '${env}-AvailabilitySet'
  location: location
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 3
  }
  sku: {
    name: 'Aligned'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = [for i in range(1, numOfVMs+1):  {
  name: '${env}-NIC-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LbName, 'BackendPool')
            }
          ]
          subnet: {
            id: webVnet.properties.subnets[0].id
          }
         
        }
      }
    ]
  }
}
]

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for i in range(1, numOfVMs + 1): {
  name: '${env}-VM-${i}'
  location: location
  properties: {
    hardwareProfile: {

      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      
      computerName: '${env}-VM-${i}'
      adminUsername: adminName
      adminPassword: adminPassword
    }
    networkProfile: {

      networkInterfaces: [
        {
          id: nic[i - 1].id
        }
      ]
    }
    availabilitySet: {
      id: availableSet.id
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
       storageUri: 'https://${storageAccountName}.blob.core.windows.net/'
      }
    }

  }

}]



resource lb 'Microsoft.Network/loadBalancers@2024-07-01' = {
  name: LbName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
        privateIPAllocationMethod:'Dynamic'
        subnet: {
          id: webVnet.properties.subnets[3].id
        }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool'
       
      }
    ]
    loadBalancingRules: [
      {
        name: 'HTTPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LbName, 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LbName, 'BackendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', LbName, 'HTTPProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 4
          enableFloatingIP: false
        }
      }
      {
        name: 'HTTPSRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LbName, 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LbName, 'BackendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', LbName, 'HTTPSProbe')
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          idleTimeoutInMinutes: 4
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        name: 'HTTPProbe'
        properties: {
          protocol: 'Http'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
          requestPath: '/health'
        }
      }
      {
        name: 'HTTPSProbe'
        properties: {
          protocol: 'Https'
          port: 443
          intervalInSeconds: 15
          numberOfProbes: 2
          requestPath: '/health'
        }
      }
    ]

  }
}
resource vmsNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: '${env}-NSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: BastionSubnetPrefix
          destinationAddressPrefix: VmsSubnetPrefix
          sourcePortRange: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: LbSubnetPrefix
          destinationAddressPrefix: VmsSubnetPrefix
          sourcePortRange: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: LbSubnetPrefix
          destinationAddressPrefix: VmsSubnetPrefix
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-ICMP'
        properties: {
          priority: 400
          protocol: 'Icmp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: BastionSubnetPrefix
          destinationAddressPrefix: VmsSubnetPrefix
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 500
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}


resource bastionIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: '${env}-BastionIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}
resource bastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: '${env}-BastionHost'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'BastionIPConfig'
        properties: {
          subnet: {
            id: webVnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionIp.id
          }
        }
      }
    ]
    enableTunneling: true
  }
  sku: {
    name: 'Standard'
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-02-02' = {
  name: '${env}LogAnalyticsWorkspace'
  location: location
  sku: {
    name: 'PerGB2018'
  }
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${env}-AppInsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: workspace.id
  }
}
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for i in range(0,numOfVMs ): {
  name: '${vm[i].name}-Diagnostics'
  scope: vm[i]
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        category: 'VirtualMachineInsights'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    storageAccountId: storageAccount.id
   
  }

}]
  