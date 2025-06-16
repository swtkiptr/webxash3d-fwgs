# Multi-stage Dockerfile that builds both CS client and websockify-c proxy
FROM emscripten/emsdk:4.0.9 AS engine

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
FROM nginx:alpine3.21 AS production

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

# Set NODE_PATH so Node.js can find modules
ENV NODE_PATH=/usr/local/lib/node_modules

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
RUN echo 'server {\n\
    listen 8080;\n\
    server_name localhost;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    # Enable CORS for all origins\n\
    add_header Access-Control-Allow-Origin *;\n\
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";\n\
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";\n\
\n\
    # Handle preflight requests\n\
    location / {\n\
        if ($request_method = '\''OPTIONS'\'') {\n\
            add_header Access-Control-Allow-Origin *;\n\
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";\n\
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";\n\
            add_header Access-Control-Max-Age 1728000;\n\
            add_header Content-Type '\''text/plain; charset=utf-8'\'';\n\
            add_header Content-Length 0;\n\
            return 204;\n\
        }\n\
        try_files $uri $uri/ =404;\n\
    }\n\
\n\
    # Serve WASM files with correct MIME type\n\
    location ~* \.wasm$ {\n\
        add_header Content-Type application/wasm;\n\
        add_header Access-Control-Allow-Origin *;\n\
    }\n\
\n\
    # Serve JS files with correct MIME type\n\
    location ~* \.js$ {\n\
        add_header Content-Type application/javascript;\n\
        add_header Access-Control-Allow-Origin *;\n\
    }\n\
\n\
    # Health check endpoint\n\
    location /health {\n\
        access_log off;\n\
        return 200 "healthy\n";\n\
        add_header Content-Type text/plain;\n\
    }\n\
}' > /etc/nginx/conf.d/default.conf

# Create startup script that runs both nginx and websockify
RUN printf '#!/bin/bash\n\
\n\
# Default configuration\n\
WEBSOCKET_PORT=${WEBSOCKET_PORT:-3000}\n\
TARGET_HOST=${TARGET_HOST:-127.0.0.1}\n\
TARGET_PORT=${TARGET_PORT:-27015}\n\
NGINX_PORT=${NGINX_PORT:-8080}\n\
\n\
echo "Starting WebXash3D All-in-One Container..."\n\
echo "Configuration:"\n\
echo "  CS Client: http://localhost:$NGINX_PORT"\n\
echo "  WebSocket Proxy: ws://localhost:$WEBSOCKET_PORT"\n\
echo "  Target Server: $TARGET_HOST:$TARGET_PORT (configurable at runtime)"\n\
echo ""\n\
echo "Note: WebSocket proxy will connect to target server when CS client connects"\n\
echo ""\n\
\n\
# Start Node.js WebSocket proxy in background\n\
echo "Starting Node.js WebSocket proxy..."\n\
echo "Command: node /usr/local/bin/websocket-proxy-server.js --port $WEBSOCKET_PORT"\n\
node /usr/local/bin/websocket-proxy-server.js --port $WEBSOCKET_PORT &\n\
WEBSOCKET_PID=$!\n\
\n\
# Wait a moment for WebSocket proxy to start\n\
sleep 2\n\
\n\
# Check if WebSocket proxy started successfully\n\
if ! kill -0 $WEBSOCKET_PID 2>/dev/null; then\n\
    echo "Warning: WebSocket proxy may not have started properly"\n\
    echo "Check logs for details"\n\
    exit 1\n\
fi\n\
\n\
echo "Node.js WebSocket proxy started (PID: $WEBSOCKET_PID)"\n\
echo ""\n\
echo "🎮 CS Client ready at: http://localhost:$NGINX_PORT"\n\
echo "🔌 WebSocket proxy ready at: ws://localhost:$WEBSOCKET_PORT"\n\
echo ""\n\
echo "To connect to a different game server, set environment variables:"\n\
echo "  TARGET_HOST=your-server-ip TARGET_PORT=27015"\n\
echo ""\n\
\n\
# Start nginx in foreground\n\
echo "Starting nginx web server..."\n\
exec nginx -g '\''daemon off;'\''\n' > /start-services.sh

# Make startup script executable
RUN chmod +x /start-services.sh

# Expose ports
EXPOSE 8080 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost 8080 && nc -z localhost 3000 || exit 1

# Set startup script as entrypoint
ENTRYPOINT ["/start-services.sh"]