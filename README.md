# BSH - Basic Hacker Tools

A collection of safe, read-only network information gathering tools. These tools allow you to view network data, scan for devices, and gather information about your network environment. **These tools do not perform any hacking, exploitation, or unauthorized access attempts** - they only display publicly available network information.

## Features

- **Network Interfaces**: View all network interfaces and their configurations
- **IP Information**: Get detailed IP address information (local and remote)
- **Device Scanner**: Discover devices on your local network
- **Port Scanner**: Check which ports are open on a host (read-only)

## Installation

### Option 1: Direct Usage

Clone this repository and run directly:

```bash
git clone <repository-url>
cd autotype
./bsh.rb help
```

### Option 2: Install as Gem (if packaged)

```bash
gem install bsh
```

## Usage

### View Network Interfaces

Show all network interfaces and their IP addresses:

```bash
bsh interfaces
# or
bsh if
```

### Get IP Information

View local IP information:

```bash
bsh ip
```

View information about a remote IP or hostname:

```bash
bsh ip 8.8.8.8
bsh ip google.com
```

### Scan Network for Devices

Scan your local network for devices:

```bash
bsh scan
```

Scan a specific network range:

```bash
bsh scan 192.168.1.0/24
bsh scan 10.0.0.0/24
```

### Scan Ports

Scan common ports on localhost:

```bash
bsh ports localhost
```

Scan specific ports on a host:

```bash
bsh ports 192.168.1.1 22 80 443
bsh ports google.com 80 443
```

## Commands

| Command | Description |
|---------|-------------|
| `interfaces`, `if` | Show network interfaces and their information |
| `ip [target]` | Show IP address information (default: local) |
| `scan [network]` | Scan network for devices (default: local network) |
| `ports [host] [ports...]` | Scan ports on a host (default: localhost, common ports) |
| `help` | Show help message |

## Examples

```bash
# View all network interfaces
bsh interfaces

# Get your local IP information
bsh ip

# Get information about Google's DNS
bsh ip 8.8.8.8

# Scan your local network for devices
bsh scan

# Scan a specific network
bsh scan 192.168.0.0/24

# Check if common ports are open on localhost
bsh ports localhost

# Check specific ports on a remote host
bsh ports 192.168.1.1 22 80 443 8080
```

## Safety & Ethics

**Important**: These tools are designed for:

- ✅ Network administration and troubleshooting
- ✅ Learning about network protocols
- ✅ Security auditing of your own networks
- ✅ Educational purposes

**Do NOT use these tools for**:

- ❌ Unauthorized network scanning
- ❌ Accessing systems without permission
- ❌ Any illegal activities

Always ensure you have permission before scanning networks or systems that you don't own or manage.

## Requirements

- Ruby 2.7+ (uses standard library, no external dependencies)
- macOS or Linux (uses system commands for some features)

## How It Works

### Network Interfaces
Uses Ruby's `Socket.getifaddrs` to enumerate all network interfaces and display their IP addresses, netmasks, and flags.

### IP Information
- Uses `Resolv` for DNS lookups
- Uses `Socket` for network operations
- Performs basic reachability tests (ping)

### Device Scanner
- Detects your local network automatically
- Uses ping to check if hosts are alive
- Queries ARP table for MAC addresses
- Performs reverse DNS lookups for hostnames

### Port Scanner
- Attempts TCP connections to specified ports
- Uses timeouts to avoid hanging
- Only checks if ports are open/closed (does not send exploit payloads)
- Displays common service names for well-known ports

## Limitations

- Port scanning is limited to TCP connections
- Device scanning may be slow on large networks (limited to 256 hosts per scan)
- Some features require appropriate system permissions
- MAC address detection depends on ARP table entries

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please ensure any new features maintain the read-only, information-gathering nature of the tool.
