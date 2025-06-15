# WebXash3D CS Client + WebSocket Proxy Usage Guide

## What This Provides

🎮 **CS Client**: Web-based Counter-Strike client  
🔌 **WebSocket Proxy**: Converts WebSocket ↔ UDP for game networking  
⚙️ **No Game Server**: You need to connect to an existing CS server  

## Quick Start

### 1. Build and Run
```bash
git clone https://github.com/swtkiptr/webxash3d-fwgs.git
cd webxash3d-fwgs
git checkout websocket-proxy-support
./build-and-run.sh
```

### 2. Access the Client
Open your browser and go to: **http://localhost:8080**

### 3. Connect to a Game Server
In the CS client, connect to any Counter-Strike server:
- **Local server**: `connect 127.0.0.1:27015`
- **Remote server**: `connect 192.168.1.100:27015`
- **Internet server**: `connect game.example.com:27015`

## How It Works

```
┌─────────────┐    WebSocket    ┌─────────────┐    UDP    ┌─────────────┐
│             │ ──────────────> │             │ ────────> │             │
│ CS Client   │                 │ websockify  │           │ Game Server │
│ (Browser)   │ <────────────── │ Proxy       │ <──────── │ (Any CS)    │
└─────────────┘    WebSocket    └─────────────┘    UDP    └─────────────┘
   localhost:8080                 localhost:3000           your-server:27015
```

## Configuration Options

### Connect to Different Servers

#### Option 1: Set at Build Time
```bash
# Connect to specific server by default
TARGET_HOST=192.168.1.100 TARGET_PORT=27016 ./build-and-run.sh
```

#### Option 2: Set with Docker Compose
```bash
# Edit all-in-one.docker-compose.yml
environment:
  - TARGET_HOST=your-server-ip
  - TARGET_PORT=27015

# Then restart
docker-compose -f all-in-one.docker-compose.yml restart
```

#### Option 3: Connect in Game
Just use the console in the CS client:
```
connect your-server-ip:27015
```

### Use Different Ports
```bash
# Use different ports for the container
CLIENT_PORT=9090 WEBSOCKET_PORT=4000 ./build-and-run.sh
```

## Finding Game Servers

### Public CS 1.6 Servers
You can connect to any public Counter-Strike 1.6 server:

1. **Find servers online**:
   - GameTracker.com
   - ServerList.games
   - CS server lists

2. **Connect in game**:
   ```
   connect server-ip:port
   ```

### Local Server Setup
If you want to run your own CS server:

#### Option 1: Docker CS Server
```bash
# Run a simple CS 1.6 server
docker run -d -p 27015:27015/udp \
  --name cs-server \
  cs16ds/server:latest
```

#### Option 2: SteamCMD + HLDS
```bash
# Install dedicated server with SteamCMD
# (More complex setup - see CS server tutorials)
```

## Troubleshooting

### Common Issues

1. **Can't connect to server**
   ```bash
   # Test if server is reachable
   nc -u server-ip 27015
   
   # Check proxy logs
   docker-compose -f all-in-one.docker-compose.yml logs
   ```

2. **WebSocket connection failed**
   ```bash
   # Check if proxy is running
   curl http://localhost:8080/health
   nc -z localhost 3000
   ```

3. **High latency/lag**
   - Use servers geographically close to you
   - Check your internet connection
   - Try different servers

### Debug Commands

```bash
# View container logs
docker-compose -f all-in-one.docker-compose.yml logs -f

# Check running processes
docker-compose -f all-in-one.docker-compose.yml exec webxash3d-all-in-one ps aux

# Test WebSocket proxy
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: test" -H "Sec-WebSocket-Version: 13" \
     http://localhost:3000/
```

## Performance Tips

### For Better Gaming Experience

1. **Use nearby servers** - Lower latency
2. **Stable internet** - Avoid WiFi if possible
3. **Close other apps** - Free up browser resources
4. **Use Chrome/Firefox** - Better WebGL performance

### Container Optimization

```bash
# Allocate more memory to container
docker run --memory=512m webxash3d-all-in-one

# Use host networking for lower latency
docker run --network=host webxash3d-all-in-one
```

## What You DON'T Need

❌ **Game Server**: This container doesn't include a CS server  
❌ **Steam**: This is a standalone web client  
❌ **CS Installation**: Everything runs in the browser  
❌ **Port Forwarding**: Only if you want others to connect to YOUR server  

## What You DO Need

✅ **Docker**: To run the container  
✅ **Web Browser**: Chrome, Firefox, Safari, Edge  
✅ **Internet**: To connect to game servers  
✅ **Game Server**: An existing CS server to connect to  

## Example Workflow

1. **Start the container**:
   ```bash
   ./build-and-run.sh
   ```

2. **Open browser**: http://localhost:8080

3. **Wait for loading**: CS client will initialize

4. **Open console**: Press `~` key

5. **Connect to server**:
   ```
   connect 192.168.1.100:27015
   ```

6. **Play**: Enjoy Counter-Strike in your browser!

## Advanced Usage

### Multiple Game Servers
```bash
# Start multiple proxy instances for different servers
docker run -d -p 3001:3000 -e TARGET_HOST=server1.com webxash3d-all-in-one
docker run -d -p 3002:3000 -e TARGET_HOST=server2.com webxash3d-all-in-one
```

### Custom Game Modes
The client supports standard CS 1.6 game modes:
- Classic Competitive
- Deathmatch
- Custom maps
- Mods (if server supports)

### LAN Gaming
```bash
# For LAN parties, use local IP
TARGET_HOST=192.168.1.10 ./build-and-run.sh
```

---

🎮 **Ready to play Counter-Strike in your browser!**

This setup gives you a complete CS client that can connect to any Counter-Strike server through the WebSocket proxy.