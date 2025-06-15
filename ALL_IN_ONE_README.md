# WebXash3D All-in-One Container

🚀 **Single Docker container** that builds and runs both the CS client and websockify-c proxy together!

⚠️ **Note**: This container provides the **CS client + WebSocket proxy only**. You need to connect to an existing Counter-Strike server.

## Features

✅ **CS Client + Proxy**: Complete web-based CS client with WebSocket proxy  
✅ **Automatic Build**: Compiles everything from source  
✅ **Lightweight Proxy**: Uses websockify-c (C-based, 1-2 MB memory)  
✅ **Connect to Any Server**: Works with any CS 1.6 server  
✅ **Health Monitoring**: Built-in health checks for both services  
✅ **CORS Enabled**: Properly configured for web browser access  

## Quick Start

### Option 1: One-Command Build & Run

```bash
# Clone repository
git clone https://github.com/swtkiptr/webxash3d-fwgs.git
cd webxash3d-fwgs
git checkout websocket-proxy-support

# Build and run everything
./build-and-run.sh
```

### Option 2: Manual Docker Commands

```bash
# Build the all-in-one container
docker-compose -f all-in-one.docker-compose.yml build

# Run the container
docker-compose -f all-in-one.docker-compose.yml up -d

# Check status
docker-compose -f all-in-one.docker-compose.yml ps
```

### Option 3: Direct Docker Build

```bash
# Build the image
docker build -f all-in-one.Dockerfile -t webxash3d-all-in-one .

# Run the container
docker run -d \
  --name webxash3d \
  -p 8080:8080 \
  -p 3000:3000 \
  -e TARGET_HOST=127.0.0.1 \
  -e TARGET_PORT=27015 \
  webxash3d-all-in-one
```

## Access Your Game

Once the container is running:

🌐 **CS Client**: http://localhost:8080  
🔌 **WebSocket Proxy**: ws://localhost:3000  
📊 **Health Check**: http://localhost:8080/health  

🎮 **To Play**: Open the CS client and connect to any CS server:
```
connect your-server-ip:27015
```  

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET_HOST` | `127.0.0.1` | Game server IP address |
| `TARGET_PORT` | `27015` | Game server port |
| `WEBSOCKET_PORT` | `3000` | WebSocket proxy port |
| `NGINX_PORT` | `8080` | Web server port |

### Connect to Game Servers

#### Option 1: Set Default Server
```bash
# Set default server (optional)
TARGET_HOST=192.168.1.100 TARGET_PORT=27016 ./build-and-run.sh
```

#### Option 2: Connect in Game
```bash
# Start container with defaults
./build-and-run.sh

# Then in CS client console:
connect 192.168.1.100:27016
connect game.example.com:27015
```

### Custom Ports

```bash
# Use different ports
CLIENT_PORT=9090 WEBSOCKET_PORT=4000 ./build-and-run.sh
```

## Architecture

```
┌─────────────────────────────────────────┐
│           Docker Container              │
│                                         │
│  ┌─────────────┐    ┌─────────────────┐ │
│  │   Nginx     │    │  websockify-c   │ │
│  │   :8080     │    │     :3000       │ │
│  │             │    │                 │ │
│  │ CS Client   │    │ WebSocket Proxy │ │
│  │ (Web UI)    │    │   (WS ↔ UDP)    │ │
│  └─────────────┘    └─────────────────┘ │
└─────────────────────────────────────────┘
           │                    │
           │                    │
    Browser Access         Game Server
   http://localhost:8080   UDP :27015
```

## Build Process

The all-in-one container performs these steps:

1. **Build websockify-c**: Compiles the C-based WebSocket proxy
2. **Build Xash3D Engine**: Compiles the game engine with Emscripten
3. **Build CS Client**: Compiles Counter-Strike client for web
4. **Configure Services**: Sets up nginx and websockify-c
5. **Apply Patches**: Configures WebSocket proxy integration

## Container Services

### Nginx Web Server (Port 8080)
- Serves the CS client web interface
- Configured with proper CORS headers
- Serves WASM files with correct MIME types
- Health check endpoint at `/health`

### websockify-c Proxy (Port 3000)
- Lightweight C-based WebSocket to UDP proxy
- Automatically connects to configured game server
- Handles bidirectional communication
- Minimal memory footprint (1-2 MB)

## Monitoring & Debugging

### Check Container Status
```bash
# View running containers
docker-compose -f all-in-one.docker-compose.yml ps

# Check health status
docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one ps aux
```

### View Logs
```bash
# All logs
docker-compose -f all-in-one.docker-compose.yml logs -f

# Nginx logs only
docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one tail -f /var/log/nginx/access.log

# websockify logs (if running with -v flag)
docker-compose -f all-in-one.docker-compose.yml logs | grep websockify
```

### Test Services
```bash
# Test web server
curl http://localhost:8080/health

# Test WebSocket proxy
nc -z localhost 3000

# Test from inside container
docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one netstat -tlnp
```

## Troubleshooting

### Common Issues

1. **Build fails with "No space left on device"**
   ```bash
   # Clean up Docker
   docker system prune -a
   ```

2. **Port already in use**
   ```bash
   # Check what's using the ports
   lsof -i :8080
   lsof -i :3000
   
   # Use different ports
   CLIENT_PORT=9090 WEBSOCKET_PORT=4000 ./build-and-run.sh
   ```

3. **Can't connect to game server**
   ```bash
   # Test UDP connectivity from container
   docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one \
     nc -u TARGET_HOST TARGET_PORT
   ```

4. **WebSocket connection fails**
   ```bash
   # Check if websockify is running
   docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one \
     ps aux | grep websockify
   ```

### Debug Mode

Run with verbose logging:

```bash
# Enable verbose websockify logging
docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one \
  websockify -v 3000 TARGET_HOST:TARGET_PORT
```

## Performance

### Resource Usage
- **Memory**: ~50-100 MB total
  - Nginx: ~10-20 MB
  - websockify-c: ~1-2 MB
  - Container overhead: ~30-50 MB
- **CPU**: Very low when idle
- **Disk**: ~200-300 MB image size

### Optimization Tips
1. Use multi-stage build to reduce final image size
2. websockify-c is much more efficient than Node.js alternatives
3. Nginx serves static files efficiently
4. Container includes health checks for reliability

## Production Deployment

### SSL/TLS Setup
For production, add SSL certificates:

```dockerfile
# Add to Dockerfile
COPY ssl/cert.pem /etc/ssl/certs/
COPY ssl/key.pem /etc/ssl/private/

# Update nginx config for HTTPS
```

### Load Balancing
For high traffic, use multiple containers:

```yaml
# docker-compose.yml
version: '3.8'
services:
  webxash3d-1:
    # ... container config
  webxash3d-2:
    # ... container config
  nginx-lb:
    # Load balancer config
```

### Monitoring
Add monitoring with Prometheus/Grafana:

```yaml
# Add to docker-compose.yml
  prometheus:
    image: prom/prometheus
  grafana:
    image: grafana/grafana
```

## Files Included

- `all-in-one.Dockerfile` - Multi-stage Docker build
- `all-in-one.docker-compose.yml` - Docker Compose configuration
- `build-and-run.sh` - Automated build and run script
- `patches/head-cs-allinone.js` - Client config for all-in-one setup
- `ALL_IN_ONE_README.md` - This documentation

## Comparison with Other Setups

| Setup | Containers | Memory | Complexity | Best For |
|-------|------------|--------|------------|----------|
| **All-in-One** | 1 | ~100 MB | Low | Development, Testing |
| **Separate Services** | 2-3 | ~150 MB | Medium | Production |
| **Manual Setup** | 0 | ~50 MB | High | Custom Deployments |

---

🎮 **Ready to play Counter-Strike in your browser!**

The all-in-one container provides the easiest way to get WebXash3D running with WebSocket proxy support.