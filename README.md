# Internal-Load-Balanced-Application
 Internal Load Balanced Application
Scenario:
Deploy an internal-only web app (intranet portal) load balanced across 3 VMs within a single Azure VNet using an Internal Load Balancer (ILB). Only internal support staff connect via Azure Bastion.

Who connects:

Support Staff → via Bastion to VMs

App users → via private IP behind ILB

Purpose:

Load balance internal traffic

Improve availability

Secure management via Bastion

Monitor backend health

Key services:

Azure Internal Load Balancer

NSGs

Azure Bastion

Availability Set

Storage Account (logs)

Application Insights

vms


# Azure Bicep IaaS Deployment with GitHub Actions

## 📖 Overview
This project automates the deployment of a full Azure IaaS infrastructure using [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) and continuous deployment via GitHub Actions.

## 🏗️ Infrastructure Components

- **Virtual Network** with multiple subnets:
  - VMs Subnet
  - Bastion Subnet
  - Users Subnet
  - Load Balancer Subnet
- **Availability Set** for high availability of virtual machines
- **Azure Load Balancer** (internal-facing)
- **Linux Virtual Machines (Ubuntu 22.04)**
  - Apache installed via Custom Script Extension
  - Health check endpoint `/health`
- **Azure Bastion** for secure RDP/SSH connectivity
- **Network Security Groups** with defined rules for SSH, HTTP, HTTPS, ICMP
- **Log Analytics Workspace**
- **Application Insights** linked to the workspace
- **Diagnostics Settings** for VMs sending logs to Log Analytics and Storage Account
- **GitHub Actions Workflow** for CI/CD deployment to Azure

## 📦 Technologies Used

- Azure Bicep
- Azure CLI
- GitHub Actions
- Ubuntu 22.04
- Apache2 Web Server

## 🚀 Deployment

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file bicep/main.bicep \
  --parameters adminPassword=<your-password>
🔐 Notes

The Load Balancer uses custom health probes.

Apache installed and health check created at /health.

📊 Monitoring & Diagnostics
Log Analytics Workspace connected to all VMs.

Application Insights instance created for web app metrics.

Azure Diagnostics settings for VMs.


📄 License
MIT
VMs


