# rocjay1-terraform

Terraform for my personal Azure subscription.

## Projects

### winlab

- Purpose: Stand up a small Windows lab to test DHCP and DNS on Windows Server 2025 for a course.
- Files:
  - `winlab/main.tf`: Azure resources (RG, VNet/Subnet, NSG, NICs, Public IP) and 6 VMs:
    - Servers (Windows Server 2025 Datacenter): `DC01`, `DC02`, `Server01`, `Server02`, `Storage01`
    - Client (Windows 11 Pro 23H2): `Client01` (only VM with a public IP; NSG opens RDP 3389)
  - `winlab/stop_vms.sh`: Helper to deallocate all lab VMs to save cost.

Quick start

- `cd winlab && terraform init && terraform apply`
- Credentials: Terraform outputs an admin username and generated password.
- RDP: Connect to `Client01` using its public IP; from there, RDP to the private server IPs as needed.
