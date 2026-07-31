# Lokinet Proxy

A lightweight **Docker** image for running [**Lokinet**](https://lokinet.io/) as a **SOCKS5 proxy** - a decentralized, privacy-preserving network built on the Oxen blockchain.

This project provides an optimized **Docker** container that runs **Lokinet** as a **SOCKS5 proxy**, enabling you to route all your traffic through the **Lokinet** decentralized network with minimal configuration. Perfect for privacy-conscious users who want to leverage **Lokinet**'s anonymous routing capabilities through a simple **Docker** deployment.

## Features

- 🔒 **Privacy-First**: Route your traffic through Lokinet's decentralized network
- 🐳 **Docker Native**: Simple containerized deployment with Docker and Docker Compose
- 📦 **Lightweight**: Based on Debian Bookworm slim image, optimized for low resource usage
- 🔄 **Auto-Updates**: GitHub Actions workflow automatically builds images with the latest commits
- 🛡️ **Secure by Default**: Uses principle of least privilege with minimal required capabilities
- 🌐 **SOCKS5 Proxy**: Built-in Dante SOCKS5 server for easy integration with other services
- ⚙️ **Configurable**: Fine-tune Lokinet behavior with environment variables

## Quick Start

### Using Docker Compose (Recommended)

1. Clone this repository:
```bash
git clone https://github.com/pasabanov/lokinet-proxy
cd lokinet-proxy
```

2. Update the image address in `docker-compose.yml`:
```yaml
image: ghcr.io/pasabanov/lokinet-proxy:latest
```

3. Start the container:
```bash
docker-compose up -d
```

4. Verify Lokinet is running:
```bash
docker-compose logs lokinet
```

### Using Docker CLI

1. Pull the image:
```bash
docker pull ghcr.io/pasabanov/lokinet-proxy:latest
```

2. Run a container from the image:
```bash
docker run -d \
  --name lokinet-proxy \
  --cap-add NET_ADMIN \
  --cap-add NET_BIND_SERVICE \
  --device /dev/net/tun:/dev/net/tun \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  -p 127.0.0.1:1051:1051 \
  -e SOCKS_PORT=1051 \
  -e LOKINET_WORKER_THREADS=1 \
  -e LOKINET_HOPS=3 \
  -e LOKINET_PATHS=6 \
  -e LOKINET_UPSTREAM_DNS=9.9.9.9 \
  -e LOKINET_EXIT_NODE=exit.loki \
  -v lokinet-data:/var/lib/lokinet \
  --restart unless-stopped \
  ghcr.io/pasabanov/lokinet-proxy:latest
```

## Configuration

### Environment Variables

- `SOCKS_PORT` (default: `1051`): The port on which the SOCKS5 proxy listens inside the container
- `LOKINET_WORKER_THREADS` (default: `1`): CPU thread limit for Lokinet daemon (1-2 recommended for VPS to prevent resource exhaustion)
- `LOKINET_HOPS` (default: `3`): Number of routing hops (affects latency and anonymity; 3 is a balance point, default is 4)
- `LOKINET_PATHS` (default: `6`): Number of backup paths (affects smoothness of path switching)
- `LOKINET_UPSTREAM_DNS` (default: `9.9.9.9`): Public DNS server for fallback resolution
- `LOKINET_EXIT_NODE` (default: `exit.loki`): Address and an optional ip range to use as an exit broker (the gateway to clearnet). Leave it empty to restrict any connections to clearnet

### Docker Compose Configuration

The `docker-compose.yml` file includes several important settings:

#### Network Capabilities
```yaml
cap_add:
  - NET_ADMIN          # Allow container to configure network and routing (required for lokitun0)
  - NET_BIND_SERVICE   # Allow binding to lower SOCKS5 ports
```

#### TUN Device
```yaml
devices:
  - /dev/net/tun:/dev/net/tun  # Required for Lokinet's virtual network interface
```

#### IPv6 Support
```yaml
sysctls:
  - net.ipv6.conf.all.disable_ipv6=0  # Lokinet requires IPv6 support
```

#### Environment Variables
```yaml
environment:
  - SOCKS_PORT=1051
  - LOKINET_WORKER_THREADS=1
  - LOKINET_HOPS=3
  - LOKINET_PATHS=6
  - LOKINET_UPSTREAM_DNS=9.9.9.9
  - LOKINET_EXIT_NODE=exit.loki
```

#### DNS Configuration
```yaml
dns:
  - 127.3.2.1   # For resolving .loki darknet domains
  - 9.9.9.9     # Backup DNS for fallback to public internet
```

#### Data Persistence
```yaml
volumes:
  - ./data:/var/lib/lokinet  # Persists node keys and state to prevent identity reset after restart
```

### Port Mapping

By default, the SOCKS5 port is exposed to localhost only. Choose one of these approaches:

#### Local Testing Only
The default configuration exposes the port only to localhost:
```yaml
ports:
  - "127.0.0.1:1051:1051"
```

#### Integration with Other Containers
If using with Xray/Marzban on the same Docker network, comment out the ports section and access via `lokinet:1051` directly:
```yaml
# ports:
#   - "127.0.0.1:1051:1051"
```

#### Custom Network
To connect to an existing Docker network:
```yaml
networks:
  default:
    name: proxy_net
    external: true
```

### Tuning Lokinet Performance

#### For VPS with Limited Resources
```yaml
environment:
  - LOKINET_WORKER_THREADS=1    # Limit CPU usage
  - LOKINET_HOPS=2              # Reduce latency
  - LOKINET_PATHS=4             # Reduce memory usage
```

#### For Maximum Anonymity
```yaml
environment:
  - LOKINET_WORKER_THREADS=2    # More processing power
  - LOKINET_HOPS=4              # More routing hops
  - LOKINET_PATHS=8             # More backup paths
```

#### For Balanced Performance
```yaml
environment:
  - LOKINET_WORKER_THREADS=1    # Default
  - LOKINET_HOPS=3              # Default (recommended)
  - LOKINET_PATHS=6             # Default
```

## Usage Examples

### Using with curl
```bash
# Test SOCKS5 proxy (if port is exposed)
curl --socks5-hostname 127.0.0.1:1051 https://example.com
```

### Using with Firefox (or its forks)
1. Open Browser Preferences → Network Settings
2. Configure SOCKS5 proxy: `127.0.0.1:1051`
3. Enable "Proxy DNS when using SOCKS v5"

Additional settings for maximum privacy:

4. Open `about:config` page
5. Find `network.proxy.allow_bypass`
6. Switch it to `false`

### Integration with Xray/Marzban
If running Xray/Marzban in the same Docker network:
```yaml
# In your Xray config
"outbounds": [
  {
    "protocol": "socks",
    "settings": {
      "servers": [
        {
          "address": "lokinet",
          "port": 1051
        }
      ]
    }
  }
]
```

## Architecture

### How It Works

1. **Lokinet Daemon**: Runs the Lokinet client with configurable parameters, creating a virtual `lokitun0` network interface
2. **Configuration Generation**: Dynamically generates `lokinet.ini` from environment variables for worker threads, hops, and paths
3. **DNS Configuration**: Sets up DNS resolution for `.loki` domains via Lokinet's DNS server (127.3.2.1) with fallback to public DNS
4. **Dante SOCKS5 Server**: Listens on the configured port and routes traffic through `lokitun0`
5. **Docker Entrypoint**: Orchestrates startup, waits for the TUN interface, configures DNS, and starts Dante dynamically

### Startup Sequence

The `docker-entrypoint.sh` script performs the following steps:

1. Configures DNS resolvers (`/etc/resolv.conf`) with Lokinet's DNS server and fallback
2. Creates the `/var/lib/lokinet` directory for node data
3. Generates `lokinet.ini` configuration file with environment variables:
   - `worker-threads`: CPU thread limit
   - `hops`: Routing hops for anonymity
   - `paths`: Backup path count
   - `upstream`: Fallback DNS server
4. Starts the Lokinet daemon in the background
5. Waits for the `lokitun0` interface to become available
6. Dynamically generates Dante SOCKS5 configuration using the `SOCKS_PORT` environment variable
7. Starts the Dante SOCKS5 server

### Image Details

- **Base Image**: `debian:bookworm-slim`
- **Size**: Optimized for minimal footprint
- **Build dependencies**: ca-certificates
- **Dependencies**: iproute2, dante-server
- **Lokinet Source**: Official Oxen repository (bookworm)

## Image Tag Examples

- `ghcr.io/pasabanov/lokinet-proxy:latest` - Latest release
- `ghcr.io/pasabanov/lokinet-proxy:1.2.3` - Specific version
- `ghcr.io/pasabanov/lokinet-proxy:sha-abc1234` - Specific commit

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs lokinet

# Verify TUN device is available
ls -la /dev/net/tun
```

### SOCKS5 proxy not responding
```bash
# Check if Dante is running
docker-compose exec lokinet ps aux | grep danted

# Test connectivity
docker-compose exec lokinet curl --socks5-hostname 127.0.0.1:1051 https://example.com
```

### DNS resolution issues
```bash
# Check DNS configuration inside container
docker-compose exec lokinet cat /etc/resolv.conf

# Test DNS resolution for .loki domains
docker-compose exec lokinet nslookup example.loki 127.3.2.1
```

### High CPU usage
If the container is consuming too much CPU:
```bash
# Reduce worker threads
docker-compose down
# Edit docker-compose.yml and set LOKINET_WORKER_THREADS=1
docker-compose up -d
```

### Slow connection
If experiencing slow speeds:
```bash
# Try reducing hops for lower latency
# Edit docker-compose.yml and set LOKINET_HOPS=2
# Or increase paths for better path switching
# Edit docker-compose.yml and set LOKINET_PATHS=8
```

### IPv6 issues
Ensure the host system supports IPv6 and the sysctl setting is applied:
```bash
docker-compose exec lokinet sysctl net.ipv6.conf.all.disable_ipv6
```

## Security Considerations

- ✅ Uses principle of least privilege (no `privileged: true`)
- ✅ Only grants necessary capabilities (NET_ADMIN, NET_BIND_SERVICE)
- ✅ Runs on Debian slim image to minimize attack surface
- ✅ Persists node keys to prevent identity reset
- ✅ Generates configuration dynamically from environment variables
- ⚠️ SOCKS5 proxy is not authenticated by default - restrict network access accordingly

## Building Locally

```bash
# Build the image
docker build -t lokinet-proxy:local .

# Run with Docker Compose
docker-compose up -d
```

## License

See the [LICENSE](LICENSE) file.

## References

- [Lokinet Official Website](https://lokinet.io/)
- [Oxen Project](https://oxen.io/)
- [Lokinet GitHub Repository](https://github.com/oxen-io/lokinet)
- [Dante SOCKS Server](https://www.inet.no/dante/)

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

---

**Privacy First** - Route your traffic through a decentralized network with Lokinet Proxy.