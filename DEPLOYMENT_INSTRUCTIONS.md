# Deployment Instructions for WebXash3D with WebSocket Proxy

## What Has Been Completed

✅ **Fixed Docker Build Issues**
- Updated apt commands to handle post-invoke script errors
- Fixed HTTPS URLs for submodules
- Enhanced Dockerfile with robust apt configuration

✅ **Implemented WebSocket Proxy System**
- Created comprehensive WebSocket to UDP proxy server (`websocket-proxy-server.js`)
- Added client-side WebSocket proxy integration in patches
- Built Docker containers for proxy server deployment
- Created full-stack Docker Compose configuration

✅ **Enhanced Documentation**
- Comprehensive WebSocket proxy documentation (`WEBSOCKET_PROXY_README.md`)
- Updated main README with proxy setup instructions
- Created startup scripts for easy deployment

✅ **Git Configuration**
- All changes committed to branch `websocket-proxy-support`
- Git configured with your credentials (swtkiptr / swkiptr@gmail.com)

## Files Created/Modified

### Core WebSocket Proxy Files
- `websocket-proxy-server.js` - Node.js WebSocket to UDP proxy server
- `package.json` - Node.js dependencies
- `websocket-proxy.Dockerfile` - Docker container for proxy
- `websocket-proxy.docker-compose.yml` - Docker Compose for proxy only
- `full-stack.docker-compose.yml` - Complete stack (proxy + client)

### Client Integration
- `patches/websocket-proxy.js` - Client-side WebSocket proxy implementation
- `patches/head-cs.js` - Enhanced with WebSocket proxy configuration
- `cs16-client.Dockerfile` - Updated to include WebSocket proxy patches

### Documentation & Scripts
- `WEBSOCKET_PROXY_README.md` - Comprehensive proxy documentation
- `start-proxy.sh` - Simple startup script for proxy server
- `README.md` - Updated with proxy setup instructions
- `DEPLOYMENT_INSTRUCTIONS.md` - This file

## Next Steps (Manual Actions Required)

### 1. Push to GitHub

Since authentication is required, you'll need to push manually:

```bash
cd webxash3d-fwgs
git push -u origin websocket-proxy-support
```

Or create a Personal Access Token and use:
```bash
git remote set-url origin https://YOUR_TOKEN@github.com/swtkiptr/webxash3d-fwgs.git
git push -u origin websocket-proxy-support
```

### 2. Test the Docker Build

```bash
# Test the CS client build
docker-compose -f cs16-client.docker-compose.yml build --no-cache

# Test the WebSocket proxy
docker-compose -f websocket-proxy.docker-compose.yml build --no-cache

# Test the full stack
docker-compose -f full-stack.docker-compose.yml build --no-cache
```

### 3. Deploy and Test

```bash
# Start the full stack
docker-compose -f full-stack.docker-compose.yml up -d

# Check services are running
docker-compose -f full-stack.docker-compose.yml ps

# Check proxy health
curl http://localhost:3000/health

# Access the CS client
# Navigate to http://localhost:8080
```

### 4. Configure for Production

1. **Update WebSocket Proxy URL** in `patches/head-cs.js`:
   ```javascript
   Module.websocket.url = 'wsproxy://your-domain.com:3000/';
   ```

2. **Set up SSL/TLS** for production deployment

3. **Configure firewall** to allow ports 3000 (proxy) and 8080 (client)

## Architecture Overview

```
Web Browser (CS Client)
    ↓ WebSocket
WebSocket Proxy Server (Port 3000)
    ↓ UDP
Game Server (Port 27015)
```

## Key Features Implemented

1. **Bidirectional Communication**: WebSocket ↔ UDP proxy
2. **Connection Management**: Automatic cleanup of stale connections
3. **Health Monitoring**: `/health` endpoint for monitoring
4. **Docker Deployment**: Complete containerization
5. **Error Handling**: Robust error handling and logging
6. **CORS Support**: Configured for web client access

## Testing the WebSocket Proxy

### Manual Testing

```javascript
// In browser console
const ws = new WebSocket('ws://localhost:3000/?host=127.0.0.1&port=27015');
ws.onopen = () => console.log('Connected to proxy');
ws.onmessage = (event) => console.log('Received:', event.data);
ws.send('test message');
```

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

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3000 and 8080 are available
2. **CORS errors**: Check proxy server CORS configuration
3. **WebSocket connection failed**: Verify proxy server is running
4. **UDP packets not forwarded**: Check target server accessibility

### Debug Commands

```bash
# Check proxy logs
docker-compose -f full-stack.docker-compose.yml logs websocket-proxy

# Check client logs
docker-compose -f full-stack.docker-compose.yml logs cs16-client

# Test UDP connectivity
nc -u target-server-ip 27015
```

## Security Considerations

- The proxy allows all origins by default (development mode)
- Consider implementing authentication for production
- Use HTTPS/WSS in production environments
- Implement rate limiting for production deployments

## Performance Notes

- Each WebSocket connection creates a UDP socket
- Connections auto-cleanup after 5 minutes of inactivity
- Proxy can handle multiple concurrent connections
- Consider load balancing for high-traffic scenarios

---

**Status**: Ready for deployment and testing
**Branch**: `websocket-proxy-support`
**Next Action**: Push to GitHub and test Docker builds