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

VMs

Storage Account (logs)

Application Insights
