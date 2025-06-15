# Multi-stage Dockerfile that builds both CS client and websockify-c proxy
FROM emscripten/emsdk:4.0.9 as engine

# Install dependencies for building
RUN dpkg --add-architecture i386
RUN mkdir -p /etc/apt/apt.conf.d/ && \
    echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean && \
    echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get -y --no-install-recommends install aptitude
RUN aptitude -y --without-recommends install git ca-certificates build-essential gcc-multilib g++-multilib libsdl2-dev:i386 libfreetype-dev:i386 libopus-dev:i386 libbz2-dev:i386 libvorbis-dev:i386 libopusfile-dev:i386 libogg-dev:i386 nodejs npm

# Set environment variables
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

# Set working directory
WORKDIR /src

# Copy source code
COPY . .

# Initialize and update submodules (including websockify-c)
RUN git submodule update --init --recursive

# Install Node.js dependencies for WebSocket proxy
WORKDIR /src
RUN npm install ws dgram

# Build the Xash3D engine
WORKDIR /src/xash3d-fwgs
ENV EMCC_CFLAGS="-s USE_SDL=2"
RUN EMSCRIPTEN=true emconfigure ./waf configure --enable-stbtt --enable-emscripten && \
    emmake ./waf build

# Apply patches to engine
WORKDIR /src
RUN sed -e '/var Module = typeof Module != "undefined" ? Module : {};/{r patches/head-cs-allinone.js' -e 'd}' -i xash3d-fwgs/build/engine/index.js
RUN sed -e '/filename = PATH.normalize(filename);/{r patches/filename.js' -e 'd}' -i xash3d-fwgs/build/engine/index.js
RUN sed -e 's/run();//g' -i xash3d-fwgs/build/engine/index.js
RUN sed -e 's/readFile(path, opts = {}) {/readFile(path, opts = {}) {console.log({path});/g' -i xash3d-fwgs/build/engine/index.js
RUN sed -e '/preInit();/{r patches/init.js' -e 'd}' -i xash3d-fwgs/build/engine/index.js
RUN sed -e '/preInit();/{r patches/websocket-proxy.js' -e '}' -i xash3d-fwgs/build/engine/index.js
RUN sed -e 's/async type="text\/javascript"/defer type="module"/' -i xash3d-fwgs/build/engine/index.html

# Build the CS client
WORKDIR /src/cs16-client
ENV EMCC_CFLAGS="-s USE_SDL=2"
RUN emcmake cmake -S . -B build && \
    cmake --build build --config Release

# Production stage with nginx
FROM nginx:alpine3.21 as production

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    netcat-openbsd \
    procps \
    nodejs \
    npm

# Copy Node.js WebSocket proxy
COPY --from=engine /src/websocket-proxy-server.js /usr/local/bin/websocket-proxy-server.js
COPY --from=engine /src/node_modules /usr/local/lib/node_modules

# Copy built CS client files
COPY --from=engine /src/cs16-client/build/3rdparty/mainui_cpp/menu_emscripten_javascript.wasm /usr/share/nginx/html/menu
COPY --from=engine /src/cs16-client/build/cl_dll/client.wasm /usr/share/nginx/html/client.wasm
COPY --from=engine /src/cs16-client/build/3rdparty/ReGameDLL_CS/regamedll/cs_emscripten_javascript.wasm /usr/share/nginx/html/server.wasm

# Copy engine files
COPY --from=engine /src/xash3d-fwgs/build/engine/index.html /usr/share/nginx/html/index.html
COPY --from=engine /src/xash3d-fwgs/build/engine/index.js /usr/share/nginx/html/index.js
COPY --from=engine /src/xash3d-fwgs/build/engine/index.wasm /usr/share/nginx/html/index.wasm
COPY --from=engine /src/xash3d-fwgs/build/filesystem/filesystem_stdio.so /usr/share/nginx/html/filesystem_stdio
COPY --from=engine /src/xash3d-fwgs/build/ref/gl/libref_gles3compat.so /usr/share/nginx/html/ref_gles3compat.so
COPY --from=engine /src/xash3d-fwgs/build/ref/soft/libref_soft.so /usr/share/nginx/html/ref_soft.so

# Patches are already applied during the build process

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

# Start Node.js WebSocket proxy in background
echo "Starting Node.js WebSocket proxy..."
echo "Command: node /usr/local/bin/websocket-proxy-server.js --port $WEBSOCKET_PORT"
cd /usr/local/lib && node /usr/local/bin/websocket-proxy-server.js --port $WEBSOCKET_PORT &
WEBSOCKET_PID=$!

# Wait a moment for WebSocket proxy to start
sleep 2

# Check if WebSocket proxy started successfully
if ! kill -0 $WEBSOCKET_PID 2>/dev/null; then
    echo "Warning: WebSocket proxy may not have started properly"
    echo "Check logs for details"
    exit 1
fi

echo "Node.js WebSocket proxy started (PID: $WEBSOCKET_PID)"
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