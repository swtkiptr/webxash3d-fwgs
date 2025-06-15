#!/bin/bash

# WebSocket Proxy using websockify-c
# Lightweight C-based WebSocket to TCP proxy

set -e

echo "Starting websockify-c WebSocket Proxy..."

# Default configuration
LISTEN_PORT=${LISTEN_PORT:-3000}
TARGET_HOST=${TARGET_HOST:-127.0.0.1}
TARGET_PORT=${TARGET_PORT:-27015}
VERBOSE=${VERBOSE:-true}

# Check if websockify binary exists
if [ ! -f "websockify-c/websockify" ]; then
    echo "Error: websockify-c not found. Building it now..."
    
    if [ ! -d "websockify-c" ]; then
        echo "Cloning websockify-c repository..."
        git clone https://github.com/mittorn/websockify-c.git
    fi
    
    echo "Compiling websockify-c..."
    cd websockify-c
    make
    cd ..
fi

echo "Configuration:"
echo "  Listen Port: $LISTEN_PORT"
echo "  Target: $TARGET_HOST:$TARGET_PORT"
echo "  Verbose: $VERBOSE"
echo ""

# Build command
CMD="./websockify-c/websockify"

if [ "$VERBOSE" = "true" ]; then
    CMD="$CMD -v"
fi

CMD="$CMD $LISTEN_PORT $TARGET_HOST:$TARGET_PORT"

echo "Starting WebSocket proxy..."
echo "Command: $CMD"
echo ""
echo "WebSocket endpoint: ws://localhost:$LISTEN_PORT/"
echo "Proxying to: $TARGET_HOST:$TARGET_PORT"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start the proxy
exec $CMD