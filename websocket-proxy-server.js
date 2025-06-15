#!/usr/bin/env node

/**
 * Simple WebSocket to UDP Proxy Server
 * For WebXash3D All-in-One Container
 */

const WebSocket = require('ws');
const dgram = require('dgram');
const url = require('url');

// Configuration
const DEFAULT_PORT = 3000;
const HEARTBEAT_INTERVAL = 30000; // 30 seconds

class WebSocketUDPProxy {
    constructor(port = DEFAULT_PORT) {
        this.port = port;
        this.connections = new Map();
        this.server = null;
        
        console.log(`WebSocket UDP Proxy starting on port ${port}`);
    }

    start() {
        this.server = new WebSocket.Server({ 
            port: this.port,
            perMessageDeflate: false
        });

        this.server.on('connection', (ws, req) => {
            this.handleConnection(ws, req);
        });

        this.server.on('listening', () => {
            console.log(`✅ WebSocket proxy listening on ws://localhost:${this.port}`);
        });

        this.server.on('error', (error) => {
            console.error('❌ WebSocket server error:', error);
        });

        // Cleanup interval
        setInterval(() => {
            this.cleanup();
        }, HEARTBEAT_INTERVAL);
    }

    handleConnection(ws, req) {
        const query = url.parse(req.url, true).query;
        const targetHost = query.host || '127.0.0.1';
        const targetPort = parseInt(query.port) || 27015;
        const protocol = query.protocol || 'udp';

        console.log(`🔌 New WebSocket connection: ${targetHost}:${targetPort} (${protocol})`);

        if (protocol !== 'udp') {
            console.error(`❌ Unsupported protocol: ${protocol}`);
            ws.close(1002, 'Unsupported protocol');
            return;
        }

        // Create UDP socket
        const udpSocket = dgram.createSocket('udp4');
        const connectionId = `${targetHost}:${targetPort}`;
        
        // Store connection
        this.connections.set(ws, {
            udpSocket,
            targetHost,
            targetPort,
            connectionId,
            lastActivity: Date.now()
        });

        // WebSocket to UDP
        ws.on('message', (data) => {
            const connection = this.connections.get(ws);
            if (!connection) return;

            connection.lastActivity = Date.now();
            
            try {
                udpSocket.send(data, targetPort, targetHost, (error) => {
                    if (error) {
                        console.error(`❌ UDP send error to ${targetHost}:${targetPort}:`, error.message);
                    }
                });
            } catch (error) {
                console.error(`❌ UDP send exception:`, error.message);
            }
        });

        // UDP to WebSocket
        udpSocket.on('message', (data, rinfo) => {
            const connection = this.connections.get(ws);
            if (!connection) return;

            connection.lastActivity = Date.now();
            
            if (ws.readyState === WebSocket.OPEN) {
                try {
                    ws.send(data);
                } catch (error) {
                    console.error(`❌ WebSocket send error:`, error.message);
                }
            }
        });

        udpSocket.on('error', (error) => {
            console.error(`❌ UDP socket error for ${targetHost}:${targetPort}:`, error.message);
            if (ws.readyState === WebSocket.OPEN) {
                ws.close(1011, 'UDP socket error');
            }
        });

        ws.on('close', (code, reason) => {
            console.log(`🔌 WebSocket disconnected from ${targetHost}:${targetPort} (${code}: ${reason})`);
            this.closeConnection(ws);
        });

        ws.on('error', (error) => {
            console.error(`❌ WebSocket error for ${targetHost}:${targetPort}:`, error.message);
            this.closeConnection(ws);
        });

        // Send connection confirmation
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                type: 'connection',
                status: 'connected',
                target: `${targetHost}:${targetPort}`
            }));
        }
    }

    closeConnection(ws) {
        const connection = this.connections.get(ws);
        if (connection) {
            try {
                connection.udpSocket.close();
            } catch (error) {
                // Socket might already be closed
            }
            this.connections.delete(ws);
        }
    }

    cleanup() {
        const now = Date.now();
        const timeout = 5 * 60 * 1000; // 5 minutes

        for (const [ws, connection] of this.connections.entries()) {
            if (now - connection.lastActivity > timeout) {
                console.log(`🧹 Cleaning up inactive connection: ${connection.connectionId}`);
                if (ws.readyState === WebSocket.OPEN) {
                    ws.close(1000, 'Timeout');
                }
                this.closeConnection(ws);
            }
        }
    }

    stop() {
        if (this.server) {
            console.log('🛑 Stopping WebSocket proxy server...');
            
            // Close all connections
            for (const ws of this.connections.keys()) {
                this.closeConnection(ws);
            }
            
            this.server.close(() => {
                console.log('✅ WebSocket proxy server stopped');
            });
        }
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    let port = DEFAULT_PORT;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--port' || args[i] === '-p') {
            port = parseInt(args[i + 1]) || DEFAULT_PORT;
            i++;
        } else if (args[i] === '--help' || args[i] === '-h') {
            console.log(`
WebSocket UDP Proxy Server

Usage: node websocket-proxy-server.js [options]

Options:
  --port, -p <port>    WebSocket server port (default: ${DEFAULT_PORT})
  --help, -h           Show this help message

Example:
  node websocket-proxy-server.js --port 3000
            `);
            process.exit(0);
        }
    }

    return { port };
}

// Main
if (require.main === module) {
    const { port } = parseArgs();
    const proxy = new WebSocketUDPProxy(port);

    // Graceful shutdown
    process.on('SIGINT', () => {
        console.log('\n🛑 Received SIGINT, shutting down gracefully...');
        proxy.stop();
        process.exit(0);
    });

    process.on('SIGTERM', () => {
        console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
        proxy.stop();
        process.exit(0);
    });

    proxy.start();
}

module.exports = WebSocketUDPProxy;