#!/bin/bash

# WebXash3D All-in-One Build and Run Script
# Builds CS client + websockify-c proxy in a single container

set -e

echo "🚀 WebXash3D All-in-One Builder"
echo "================================"
echo ""

# Configuration
TARGET_HOST=${TARGET_HOST:-127.0.0.1}
TARGET_PORT=${TARGET_PORT:-27015}
CLIENT_PORT=${CLIENT_PORT:-8080}
WEBSOCKET_PORT=${WEBSOCKET_PORT:-3000}

echo "Configuration:"
echo "  Target Server: $TARGET_HOST:$TARGET_PORT"
echo "  CS Client URL: http://localhost:$CLIENT_PORT"
echo "  WebSocket Proxy: ws://localhost:$WEBSOCKET_PORT"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ Error: docker-compose is not installed."
    exit 1
fi

echo "🔨 Building all-in-one container..."
echo "This may take several minutes on first build..."
echo ""

# Build the container
docker-compose -f all-in-one.docker-compose.yml build --no-cache

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo ""

# Ask user if they want to start the container
read -p "🚀 Start the container now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting WebXash3D All-in-One container..."
    
    # Stop any existing container
    docker-compose -f all-in-one.docker-compose.yml down 2>/dev/null || true
    
    # Start the container
    docker-compose -f all-in-one.docker-compose.yml up -d
    
    echo ""
    echo "🎉 Container started successfully!"
    echo ""
    echo "📋 Access Information:"
    echo "  🌐 CS Client: http://localhost:$CLIENT_PORT"
    echo "  🔌 WebSocket Proxy: ws://localhost:$WEBSOCKET_PORT"
    echo "  🎯 Target Server: $TARGET_HOST:$TARGET_PORT"
    echo ""
    echo "📊 Container Status:"
    docker-compose -f all-in-one.docker-compose.yml ps
    echo ""
    echo "📝 Useful Commands:"
    echo "  View logs: docker-compose -f all-in-one.docker-compose.yml logs -f"
    echo "  Stop container: docker-compose -f all-in-one.docker-compose.yml down"
    echo "  Restart: docker-compose -f all-in-one.docker-compose.yml restart"
    echo ""
    
    # Wait a moment and check health
    echo "⏳ Waiting for services to start..."
    sleep 10
    
    # Check if services are responding
    echo "🔍 Health Check:"
    if curl -s http://localhost:$CLIENT_PORT/health >/dev/null 2>&1; then
        echo "  ✅ Web server is responding"
    else
        echo "  ⚠️  Web server not yet ready"
    fi
    
    if nc -z localhost $WEBSOCKET_PORT 2>/dev/null; then
        echo "  ✅ WebSocket proxy is listening"
    else
        echo "  ⚠️  WebSocket proxy not yet ready"
    fi
    
    echo ""
    echo "🎮 Ready to play! Open http://localhost:$CLIENT_PORT in your browser"
    
else
    echo ""
    echo "✅ Build completed. To start later, run:"
    echo "  docker-compose -f all-in-one.docker-compose.yml up -d"
fi

echo ""
echo "🔧 Advanced Usage:"
echo "  Custom target server:"
echo "    TARGET_HOST=192.168.1.100 TARGET_PORT=27016 $0"
echo ""
echo "  Custom ports:"
echo "    CLIENT_PORT=9090 WEBSOCKET_PORT=4000 $0"