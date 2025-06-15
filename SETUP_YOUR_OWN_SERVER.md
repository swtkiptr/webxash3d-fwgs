# Setup Your Own WebSocket Proxy Server

## Quick Start (5 minutes)

### Option 1: Docker (Easiest)

```bash
# 1. Clone the repository
git clone https://github.com/swtkiptr/webxash3d-fwgs.git
cd webxash3d-fwgs
git checkout websocket-proxy-support

# 2. Start the WebSocket proxy
docker-compose -f websocket-proxy.docker-compose.yml up -d

# 3. Test it's working
curl http://localhost:3000/health

# 4. Your WebSocket server is now running at ws://localhost:3000/
```

### Option 2: Node.js Direct

```bash
# 1. Clone the repository
git clone https://github.com/swtkiptr/webxash3d-fwgs.git
cd webxash3d-fwgs
git checkout websocket-proxy-support

# 2. Install Node.js dependencies
npm install

# 3. Start the server
node websocket-proxy-server.js

# 4. Your WebSocket server is now running at ws://localhost:3000/
```

### Option 3: Using Startup Script

```bash
# 1. Clone the repository
git clone https://github.com/swtkiptr/webxash3d-fwgs.git
cd webxash3d-fwgs
git checkout websocket-proxy-support

# 2. Make script executable and run
chmod +x start-proxy.sh
./start-proxy.sh

# 3. Your WebSocket server is now running at ws://localhost:3000/
```

## Configure Your Client

### Method 1: Edit the patch file directly

Edit `patches/head-cs.js` line 17:

```javascript
// Change from:
Module.websocket.url = 'wsproxy://the-swank.pp.ua:3000/';

// To your server:
Module.websocket.url = 'wsproxy://localhost:3000/';
```

### Method 2: Set environment variable in Docker

Edit `cs16-client.Dockerfile` or set environment variable:

```dockerfile
ENV WEBSOCKET_PROXY_URL=wsproxy://localhost:3000/
```

### Method 3: Runtime configuration

Add this to your HTML page:

```html
<script>
window.Module = window.Module || {};
window.Module.websocket = { url: 'wsproxy://localhost:3000/' };
</script>
```

## Deploy to Production

### 1. Get a Domain/Server

- Use any cloud provider (AWS, DigitalOcean, etc.)
- Or use a VPS with public IP
- Ensure ports 3000 and 8080 are open

### 2. Update Configuration

```javascript
// For production, use your domain:
Module.websocket.url = 'wsproxy://your-domain.com:3000/';
```

### 3. Use SSL/TLS (Recommended)

For production, use WSS (secure WebSocket):

```javascript
Module.websocket.url = 'wsproxy://your-domain.com:443/';
```

And configure your server with SSL certificates.

## Test Your Server

### Health Check
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "connections": 0,
  "uptime": 123
}
```

### WebSocket Test
```javascript
// In browser console:
const ws = new WebSocket('ws://localhost:3000/?host=127.0.0.1&port=27015');
ws.onopen = () => console.log('Connected to your proxy!');
ws.onmessage = (event) => console.log('Received:', event.data);
```

## Server Configuration

### Environment Variables

- `PORT` - Server port (default: 3000)
- `HOST` - Server host (default: 0.0.0.0)
- `NODE_ENV` - Environment (default: production)

### Custom Port Example

```bash
# Run on port 8080 instead
PORT=8080 node websocket-proxy-server.js
```

## Full Stack Deployment

To run both the CS client and WebSocket proxy together:

```bash
# Build and start everything
docker-compose -f full-stack.docker-compose.yml up -d

# Access CS client at: http://localhost:8080
# WebSocket proxy at: ws://localhost:3000
```

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using port 3000
   lsof -i :3000
   # Kill the process or use different port
   PORT=3001 node websocket-proxy-server.js
   ```

2. **CORS errors**
   - The server allows all origins by default
   - Check browser console for specific errors

3. **Connection refused**
   - Ensure the server is running: `curl http://localhost:3000/health`
   - Check firewall settings

4. **WebSocket connection failed**
   - Verify the URL format: `ws://localhost:3000/?host=TARGET_IP&port=TARGET_PORT`
   - Check server logs for errors

### Debug Commands

```bash
# Check if server is running
ps aux | grep node

# Check server logs (Docker)
docker-compose -f websocket-proxy.docker-compose.yml logs -f

# Test UDP connectivity to game server
nc -u game-server-ip 27015
```

## Security Notes

- Default configuration allows all origins (development mode)
- For production, implement proper authentication
- Use HTTPS/WSS in production
- Consider rate limiting for public deployments

---

**Your WebSocket proxy server is now ready!** 🎉

Replace `wsproxy://the-swank.pp.ua:3000/` with `wsproxy://localhost:3000/` (or your domain) in the client configuration.