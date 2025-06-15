# Multi-stage Dockerfile that builds both CS client and websockify-c proxy
FROM emscripten/emsdk:4.0.9 as engine

# Install dependencies for building
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        gcc \
        make \
        git \
        build-essential \
        libc6-dev:i386 \
        linux-libc-dev:i386 \
        python3 \
        python3-pip \
        wget \
        curl \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /src

# Copy source code
COPY . .

# Initialize and update submodules (including websockify-c)
RUN git submodule update --init --recursive

# Build websockify-c proxy
WORKDIR /src/websockify-c
RUN make clean && make

# Build the CS client engine
WORKDIR /src
RUN python3 waf configure -T release --enable-stb --disable-werror
RUN python3 waf build

# Build the CS client
WORKDIR /src/cs16-client
RUN make

# Production stage with nginx
FROM nginx:alpine3.21 as production

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    netcat-openbsd \
    procps

# Copy websockify-c binary
COPY --from=engine /src/websockify-c/websockify /usr/local/bin/websockify

# Copy built CS client files
COPY --from=engine /src/cs16-client/*.wasm /usr/share/nginx/html/
COPY --from=engine /src/cs16-client/*.js /usr/share/nginx/html/
COPY --from=engine /src/cs16-client/*.data /usr/share/nginx/html/

# Copy web assets
COPY --from=engine /src/cs16-client/*.html /usr/share/nginx/html/
COPY --from=engine /src/cs16-client/*.css /usr/share/nginx/html/

# Copy patches and apply them
COPY --from=engine /src/patches/ /tmp/patches/
RUN if [ -f /tmp/patches/head-cs-allinone.js ]; then \
        cp /tmp/patches/head-cs-allinone.js /usr/share/nginx/html/head-cs.js; \
    elif [ -f /tmp/patches/head-cs.js ]; then \
        cp /tmp/patches/head-cs.js /usr/share/nginx/html/; \
    fi && \
    if [ -f /tmp/patches/websocket-proxy.js ]; then \
        cp /tmp/patches/websocket-proxy.js /usr/share/nginx/html/; \
    fi

# Create nginx configuration
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 8080;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Enable CORS for all origins
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";

    # Handle preflight requests
    location / {
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
        try_files $uri $uri/ =404;
    }

    # Serve WASM files with correct MIME type
    location ~* \.wasm$ {
        add_header Content-Type application/wasm;
        add_header Access-Control-Allow-Origin *;
    }

    # Serve JS files with correct MIME type
    location ~* \.js$ {
        add_header Content-Type application/javascript;
        add_header Access-Control-Allow-Origin *;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Create startup script that runs both nginx and websockify
RUN cat > /start-services.sh << 'EOF'
#!/bin/bash

# Default configuration
WEBSOCKET_PORT=${WEBSOCKET_PORT:-3000}
TARGET_HOST=${TARGET_HOST:-127.0.0.1}
TARGET_PORT=${TARGET_PORT:-27015}
NGINX_PORT=${NGINX_PORT:-8080}

echo "Starting WebXash3D All-in-One Container..."
echo "Configuration:"
echo "  CS Client: http://localhost:$NGINX_PORT"
echo "  WebSocket Proxy: ws://localhost:$WEBSOCKET_PORT"
echo "  Target Server: $TARGET_HOST:$TARGET_PORT (configurable at runtime)"
echo ""
echo "Note: WebSocket proxy will connect to target server when CS client connects"
echo ""

# Start websockify-c proxy in background
echo "Starting websockify-c proxy..."
echo "Command: websockify -v $WEBSOCKET_PORT $TARGET_HOST:$TARGET_PORT"
websockify -v $WEBSOCKET_PORT $TARGET_HOST:$TARGET_PORT &
WEBSOCKIFY_PID=$!

# Wait a moment for websockify to start
sleep 2

# Check if websockify started successfully
if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "Warning: websockify may not have started properly"
    echo "This is normal if target server is not available yet"
    echo "websockify will attempt to connect when CS client connects"
fi

echo "websockify-c proxy started (PID: $WEBSOCKIFY_PID)"
echo ""
echo "🎮 CS Client ready at: http://localhost:$NGINX_PORT"
echo "🔌 WebSocket proxy ready at: ws://localhost:$WEBSOCKET_PORT"
echo ""
echo "To connect to a different game server, set environment variables:"
echo "  TARGET_HOST=your-server-ip TARGET_PORT=27015"
echo ""

# Start nginx in foreground
echo "Starting nginx web server..."
exec nginx -g 'daemon off;'
EOF

# Make startup script executable
RUN chmod +x /start-services.sh

# Expose ports
EXPOSE 8080 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost 8080 && nc -z localhost 3000 || exit 1

# Set startup script as entrypoint
ENTRYPOINT ["/start-services.sh"]