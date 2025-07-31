# Hardware Infrastructure for n8n Self-Hosting Project

## Device Overview

### MacBook Pro (Testing/Development Environment)
- **Model**: MacBook Pro (MNWA3LL/A)
- **Chip**: Apple M2 Max (12 cores: 8 performance, 4 efficiency)
- **RAM**: 32 GB
- **OS**: macOS 15.5.0
- **Tailscale IP**: 100.88.6.111
- **Role**: Initial Docker testing, development, workflow prototyping

### Office Tower (Primary Production Target)
- **Name**: TrustandObey
- **Processor**: Intel Core i5-4460 @ 3.20 GHz
- **RAM**: 16 GB
- **OS**: Windows 11 RTM (64-bit, x64-based)
- **Tailscale IP**: 100.66.187.49
- **Role**: 24/7 production hosting, higher CPU performance

### Office Laptop (Backup/Alternative)
- **Name**: 7t
- **Processor**: Intel Core i3-7130U @ 2.70 GHz
- **RAM**: 16 GB (15.9 GB usable)
- **OS**: Windows 11 22H2 (64-bit, x64-based)
- **Tailscale IP**: 100.69.107.44
- **Role**: Fallback option, lower performance backup

## Network Connectivity
- **VPN/Mesh**: All devices connected via Tailscale mesh network
- **Secure Access**: Cross-device management through private IP addresses
- **Internet**: Dynamic ISP IP addresses (no static IP confirmed)

## Hardware Considerations
- **Performance Priority**: Tower prioritized for production due to higher CPU
- **Memory**: All devices have adequate RAM for n8n workloads (16-32GB)
- **Architecture**: Mixed ARM64 (Mac) and x64 (Windows) - Docker images available for both
- **Availability**: Tower provides best uptime for 24/7 operations

## References
- See `Network_Configuration.md` for Tailscale and domain setup details
- See `Software_Environment.md` for installed software on each device