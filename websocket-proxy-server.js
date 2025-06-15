#!/usr/bin/env node

/**
 * WebSocket to UDP Proxy Server
 * Allows web-based CS clients to connect to UDP game servers
 */

const WebSocket = require('ws');
const dgram = require('dgram');
const url = require('url');
const http = require('http');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Connection tracking
const connections = new Map();
const udpSockets = new Map();

// Create HTTP server
const server = http.createServer();

// Create WebSocket server
const wss = new WebSocket.Server({ 
    server,
    verifyClient: (info) => {
        // Add CORS headers
        const origin = info.origin;
        console.log('WebSocket connection attempt from origin:', origin);
        return true; // Allow all origins for now
    }
});

console.log(`WebSocket to UDP Proxy Server starting on ${HOST}:${PORT}`);

wss.on('connection', (ws, request) => {
    const query = url.parse(request.url, true).query;
    const targetHost = query.host;
    const targetPort = parseInt(query.port);
    const protocol = query.protocol || 'udp';
    
    if (!targetHost || !targetPort) {
        console.error('Missing host or port in WebSocket connection');
        ws.close(1008, 'Missing host or port parameters');
        return;
    }
    
    console.log(`New WebSocket connection: ${targetHost}:${targetPort} (${protocol})`);
    
    const connectionId = `${ws._socket.remoteAddress}:${ws._socket.remotePort}->${targetHost}:${targetPort}`;
    
    // Create UDP socket for this connection
    const udpSocket = dgram.createSocket('udp4');
    const socketKey = `${targetHost}:${targetPort}`;
    
    // Store connection info
    connections.set(ws, {
        id: connectionId,
        targetHost,
        targetPort,
        udpSocket,
        socketKey,
        lastActivity: Date.now()
    });
    
    udpSockets.set(socketKey, udpSocket);
    
    // Handle UDP socket events
    udpSocket.on('message', (msg, rinfo) => {
        if (ws.readyState === WebSocket.OPEN) {
            try {
                ws.send(msg);
                connections.get(ws).lastActivity = Date.now();
            } catch (error) {
                console.error('Error sending UDP message to WebSocket:', error);
            }
        }
    });
    
    udpSocket.on('error', (error) => {
        console.error(`UDP socket error for ${targetHost}:${targetPort}:`, error);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close(1011, 'UDP socket error');
        }
    });
    
    // Handle WebSocket events
    ws.on('message', (data) => {
        try {
            udpSocket.send(data, targetPort, targetHost, (error) => {
                if (error) {
                    console.error(`Error sending to UDP ${targetHost}:${targetPort}:`, error);
                }
            });
            connections.get(ws).lastActivity = Date.now();
        } catch (error) {
            console.error('Error processing WebSocket message:', error);
        }
    });
    
    ws.on('close', (code, reason) => {
        console.log(`WebSocket closed: ${connectionId} (${code}: ${reason})`);
        cleanup(ws);
    });
    
    ws.on('error', (error) => {
        console.error(`WebSocket error for ${connectionId}:`, error);
        cleanup(ws);
    });
    
    // Send initial connection confirmation
    if (ws.readyState === WebSocket.OPEN) {
        ws.send(Buffer.from('PROXY_CONNECTED'));
    }
});

function cleanup(ws) {
    const connection = connections.get(ws);
    if (connection) {
        const { udpSocket, socketKey } = connection;
        
        // Close UDP socket
        try {
            udpSocket.close();
        } catch (error) {
            console.error('Error closing UDP socket:', error);
        }
        
        // Remove from tracking
        connections.delete(ws);
        udpSockets.delete(socketKey);
        
        console.log(`Cleaned up connection: ${connection.id}`);
    }
}

// Periodic cleanup of stale connections
setInterval(() => {
    const now = Date.now();
    const staleTimeout = 5 * 60 * 1000; // 5 minutes
    
    connections.forEach((connection, ws) => {
        if (now - connection.lastActivity > staleTimeout) {
            console.log(`Closing stale connection: ${connection.id}`);
            ws.close(1000, 'Connection timeout');
        }
    });
}, 60000); // Check every minute

// Handle server shutdown gracefully
process.on('SIGINT', () => {
    console.log('\nShutting down WebSocket proxy server...');
    
    // Close all connections
    connections.forEach((connection, ws) => {
        ws.close(1001, 'Server shutting down');
    });
    
    // Close WebSocket server
    wss.close(() => {
        console.log('WebSocket server closed');
        process.exit(0);
    });
});

// Add CORS headers to HTTP requests
server.on('request', (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'ok',
            connections: connections.size,
            uptime: process.uptime()
        }));
        return;
    }
    
    res.writeHead(404);
    res.end('WebSocket Proxy Server');
});

// Start the server
server.listen(PORT, HOST, () => {
    console.log(`WebSocket to UDP Proxy Server running on ws://${HOST}:${PORT}`);
    console.log('Health check available at http://' + HOST + ':' + PORT + '/health');
});

// Error handling
server.on('error', (error) => {
    console.error('Server error:', error);
    process.exit(1);
});

wss.on('error', (error) => {
    console.error('WebSocket server error:', error);
});