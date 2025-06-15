# Using mittorn/websockify-c for WebSocket Proxy

## Why websockify-c is Better

✅ **Lightweight**: Written in C, much smaller footprint than Node.js  
✅ **Simple**: No dependencies, just compile and run  
✅ **Fast**: Native C performance  
✅ **No SSL overhead**: Perfect for local development  
✅ **Battle-tested**: Based on the original websockify  

## Quick Setup

### 1. Download and Compile websockify-c

```bash
# Clone the websockify-c repository
git clone https://github.com/mittorn/websockify-c.git
cd websockify-c

# Compile (requires gcc)
make

# You now have a 'websockify' binary
```

### 2. Run the WebSocket Proxy

```bash
# Basic usage: websockify [listen_port] [target_host:target_port]
./websockify 3000 127.0.0.1:27015

# With verbose output
./websockify -v 3000 127.0.0.1:27015

# Run in background
./websockify -D 3000 127.0.0.1:27015
```

### 3. Update Your Client Configuration

In `patches/head-cs.js`, change:
```javascript
// From:
Module.websocket.url = 'wsproxy://the-swank.pp.ua:3000/';

// To:
Module.websocket.url = 'wsproxy://localhost:3000/';
```

## Docker Integration

### Option 1: Add to Existing Dockerfile

Add this to your `cs16-client.Dockerfile`:

```dockerfile
# Install websockify-c
RUN apt-get update && apt-get install -y gcc make git && \
    git clone https://github.com/mittorn/websockify-c.git /tmp/websockify-c && \
    cd /tmp/websockify-c && make && \
    cp websockify /usr/local/bin/ && \
    rm -rf /tmp/websockify-c && \
    apt-get remove -y gcc make git && \
    apt-get autoremove -y

# Start websockify in background
RUN echo '#!/bin/bash\nwebsockify -D 3000 127.0.0.1:27015 &\nexec "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

### Option 2: Separate Container

Create `websockify-c.Dockerfile`:

```dockerfile
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y gcc make git && \
    git clone https://github.com/mittorn/websockify-c.git /app && \
    cd /app && make && \
    apt-get remove -y gcc make git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

EXPOSE 3000

CMD ["./websockify", "-v", "3000", "host.docker.internal:27015"]
```

### Option 3: Docker Compose

Create `websockify-c.docker-compose.yml`:

```yaml
version: '3.8'

services:
  websockify-c:
    build:
      context: .
      dockerfile: websockify-c.Dockerfile
    container_name: websockify-c-proxy
    ports:
      - "3000:3000"
    restart: unless-stopped
    command: ["./websockify", "-v", "3000", "host.docker.internal:27015"]
```

## Usage Examples

### Local Game Server
```bash
# If you have a CS server running on localhost:27015
./websockify 3000 127.0.0.1:27015
```

### Remote Game Server
```bash
# Connect to a remote server
./websockify 3000 192.168.1.100:27015
```

### Multiple Ports with Whitelist
```bash
# Create whitelist file
echo -e "27015\n27016\n27017" > ports.txt

# Run with whitelist (allows dynamic port selection)
./websockify -w ports.txt 3000
```

## Command Line Options

```
Usage: websockify [options] [source_addr:]source_port target_addr{:target_port}

  --verbose|-v         verbose messages and per frame traffic
  --daemon|-D          become a daemon (background process)
  --whitelist|-w LIST  new-line separated target port whitelist file
  --pattern|-P         target port request pattern. Default: '/%d'
  --pid|-p             desired path of pid file
```

## Integration with Your Current Setup

### Replace Node.js Version

1. **Remove Node.js files** (optional):
   ```bash
   rm websocket-proxy-server.js package.json
   rm websocket-proxy.Dockerfile websocket-proxy.docker-compose.yml
   ```

2. **Add websockify-c**:
   ```bash
   git clone https://github.com/mittorn/websockify-c.git
   cd websockify-c && make
   ```

3. **Update startup script**:
   ```bash
   #!/bin/bash
   echo "Starting websockify-c proxy..."
   ./websockify-c/websockify -v 3000 127.0.0.1:27015
   ```

### Keep Both Options

You can keep both implementations and choose which one to use:

```bash
# Use C version (lightweight)
./websockify-c/websockify 3000 127.0.0.1:27015

# Use Node.js version (more features)
node websocket-proxy-server.js
```

## Performance Comparison

| Feature | websockify-c | Node.js Version |
|---------|--------------|-----------------|
| Memory Usage | ~1-2 MB | ~20-50 MB |
| CPU Usage | Very Low | Low |
| Startup Time | Instant | ~1-2 seconds |
| Dependencies | None | Node.js + npm |
| Binary Size | ~100KB | ~50MB+ |

## Testing

```bash
# Start the proxy
./websockify -v 3000 127.0.0.1:27015

# Test with curl (should see WebSocket upgrade)
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: test" -H "Sec-WebSocket-Version: 13" \
     http://localhost:3000/

# Test from browser console
const ws = new WebSocket('ws://localhost:3000/');
ws.onopen = () => console.log('Connected via websockify-c!');
```

## Advantages of websockify-c

1. **No runtime dependencies** - just compile and run
2. **Tiny memory footprint** - perfect for embedded systems
3. **Fast startup** - no JavaScript engine overhead
4. **Simple deployment** - single binary
5. **Proven stability** - based on original websockify

This is definitely a better choice for production deployments where you want minimal overhead!