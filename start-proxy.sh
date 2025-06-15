#!/bin/bash

# WebSocket Proxy Startup Script for WebXash3D

set -e

echo "Starting WebXash3D WebSocket Proxy..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js 14+ to run the proxy server."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Please install npm to manage dependencies."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install
fi

# Set default environment variables
export PORT=${PORT:-3000}
export HOST=${HOST:-0.0.0.0}
export NODE_ENV=${NODE_ENV:-production}

echo "Configuration:"
echo "  Port: $PORT"
echo "  Host: $HOST"
echo "  Environment: $NODE_ENV"
echo ""

# Start the proxy server
echo "Starting WebSocket to UDP proxy server..."
echo "Health check will be available at: http://$HOST:$PORT/health"
echo "WebSocket endpoint: ws://$HOST:$PORT/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

node websocket-proxy-server.js