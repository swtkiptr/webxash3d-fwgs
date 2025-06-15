# WebSocket Proxy for WebXash3D Counter-Strike Client

This implementation provides WebSocket to UDP proxy functionality, allowing web-based Counter-Strike clients to connect to traditional UDP game servers.

## Overview

Web browsers cannot directly make UDP connections due to security restrictions. This proxy server bridges the gap by:

1. Accepting WebSocket connections from the web client
2. Converting WebSocket messages to UDP packets
3. Forwarding packets to the target game server
4. Relaying responses back to the web client

## Architecture

```
Web Client (WebSocket) <-> Proxy Server <-> Game Server (UDP)
```

## Components

### 1. Client-Side Integration

- **patches/head-cs.js**: Enhanced with WebSocket proxy configuration
- **patches/websocket-proxy.js**: Complete WebSocket proxy client implementation

### 2. Proxy Server

- **websocket-proxy-server.js**: Node.js WebSocket to UDP proxy server
- **package.json**: Node.js dependencies
- **websocket-proxy.Dockerfile**: Docker container for the proxy
- **websocket-proxy.docker-compose.yml**: Docker Compose configuration

## Setup Instructions

### Option 1: Docker Deployment

1. **Build and run the WebSocket proxy:**
   ```bash
   docker-compose -f websocket-proxy.docker-compose.yml up -d
   ```

2. **Build the CS client with proxy support:**
   ```bash
   docker-compose -f cs16-client.docker-compose.yml build --no-cache
   docker-compose -f cs16-client.docker-compose.yml up -d
   ```

### Option 2: Manual Node.js Deployment

1. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

2. **Start the proxy server:**
   ```bash
   npm start
   ```

3. **Build the client normally**

## Configuration

### Proxy Server Configuration

Environment variables for the proxy server:

- `PORT`: Server port (default: 3000)
- `HOST`: Bind address (default: 0.0.0.0)
- `NODE_ENV`: Environment (production/development)

### Client Configuration

The WebSocket proxy URL is configured in `patches/head-cs.js`:

```javascript
Module.websocket.url = 'wsproxy://the-swank.pp.ua:3000/';
```

Change this to point to your proxy server:

```javascript
Module.websocket.url = 'wsproxy://your-proxy-server.com:3000/';
```

## Usage

### Connecting to Game Servers

The client will automatically use the WebSocket proxy when connecting to game servers. The proxy handles the protocol conversion transparently.

### Connection Format

WebSocket connections use the following URL format:
```
ws://proxy-server:3000/?host=game-server-ip&port=game-server-port&protocol=udp
```

### Health Monitoring

The proxy server provides a health check endpoint:
```
GET http://proxy-server:3000/health
```

Response:
```json
{
  "status": "ok",
  "connections": 5,
  "uptime": 3600
}
```

## API Reference

### Client-Side API

#### Module.websocketProxyConnect(host, port, protocol)

Creates a WebSocket connection to a game server through the proxy.

**Parameters:**
- `host` (string): Target server hostname/IP
- `port` (number): Target server port
- `protocol` (string): Protocol type (default: 'udp')

**Returns:** Connection object with methods:
- `send(data)`: Send data to the server
- `close()`: Close the connection
- Event handlers: `onopen`, `onmessage`, `onclose`, `onerror`

**Example:**
```javascript
const connection = Module.websocketProxyConnect('127.0.0.1', 27015, 'udp');

connection.onopen = function() {
    console.log('Connected to game server');
};

connection.onmessage = function(event) {
    console.log('Received data:', event.data);
};

connection.send(gamePacket);
```

#### Module.getActiveConnections()

Returns an array of all active WebSocket proxy connections.

#### Module.cleanupWebSocketConnections()

Manually cleanup stale connections.

## Security Considerations

1. **CORS**: The proxy server allows all origins by default. Restrict this in production.
2. **Rate Limiting**: Consider implementing rate limiting for production use.
3. **Authentication**: Add authentication if needed for your use case.
4. **Firewall**: Ensure proper firewall rules for the proxy server.

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Ensure the proxy server is running
   - Check firewall settings
   - Verify the proxy URL in client configuration

2. **WebSocket Connection Failed**
   - Check browser console for errors
   - Verify CORS settings
   - Ensure WebSocket support in browser

3. **UDP Packets Not Forwarded**
   - Check proxy server logs
   - Verify target server is reachable
   - Check UDP port accessibility

### Debugging

Enable debug logging in the proxy server:
```bash
DEBUG=* node websocket-proxy-server.js
```

Check browser console for client-side WebSocket errors.

## Performance Considerations

- Each WebSocket connection creates a corresponding UDP socket
- Connections are automatically cleaned up after 5 minutes of inactivity
- The proxy server can handle multiple concurrent connections
- Consider using a load balancer for high-traffic scenarios

## Development

### Running in Development Mode

```bash
npm run dev
```

This uses nodemon for automatic restarts on code changes.

### Testing

Test the proxy server health:
```bash
curl http://localhost:3000/health
```

Test WebSocket connection:
```javascript
const ws = new WebSocket('ws://localhost:3000/?host=127.0.0.1&port=27015');
ws.onopen = () => console.log('Connected');
ws.onmessage = (event) => console.log('Received:', event.data);
```

## License

This WebSocket proxy implementation is released under the same license as the main WebXash3D project (GPL-3.0).