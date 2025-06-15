FROM debian:bullseye-slim

# Install build dependencies
RUN apt-get update && \
    apt-get install -y gcc make git && \
    rm -rf /var/lib/apt/lists/*

# Clone and build websockify-c
RUN git clone https://github.com/mittorn/websockify-c.git /app && \
    cd /app && \
    make && \
    # Clean up build dependencies to reduce image size
    apt-get remove -y gcc make git && \
    apt-get autoremove -y && \
    apt-get clean

WORKDIR /app

# Expose the WebSocket port
EXPOSE 3000

# Default command - can be overridden
CMD ["./websockify", "-v", "3000", "host.docker.internal:27015"]