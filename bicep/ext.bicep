param location string = resourceGroup().location
param vmName array

resource vmExtensions 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = [for name in vmName: {
  name: '${name}/apache-install'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: '''
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo mkdir -p /var/www/html
echo "healthy" | sudo tee /var/www/html/health
sudo systemctl enable apache2
sudo systemctl start apache2

'''
    }
  }
}]

output vmIds array = [for name in vmName: resourceId('Microsoft.Compute/virtualMachines', name)]
