# ─────────────────────────────────────────────
# Stage 1: Builder
# ─────────────────────────────────────────────
FROM ubuntu:24.04 AS builder

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libssl-dev \
    libboost-all-dev \
    libyaml-cpp-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository
WORKDIR /src
RUN git clone --depth=1 https://github.com/MortezaBashsiz/nipovpn.git .

# Build (Release mode)
RUN mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j$(nproc)


# ─────────────────────────────────────────────
# Stage 2: Runtime
# ─────────────────────────────────────────────
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install only the shared libraries needed at runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libboost-regex1.83.0 \
    libyaml-cpp0.8 \
    && rm -rf /var/lib/apt/lists/*

# Copy built binaries from builder stage
COPY --from=builder /src/build/core/nipovpn /usr/local/bin/nipovpn

# Create log directory and default log file
RUN mkdir -p /var/log/nipovpn \
    && touch /var/log/nipovpn/nipovpn.log

# Create config directory
RUN mkdir -p /etc/nipovpn

# Copy default config files from builder stage (if they exist)
COPY --from=builder /src/nipovpn/etc/nipovpn/ /etc/nipovpn/

# Expose common ports:
#   443  → server default listen port
#   8080 → agent default listen port
EXPOSE 443 8080

# MODE: "server" or "agent" — override at runtime with:
#   docker run ... -e MODE=agent
ENV MODE=server

# CONFIG: path to the config file inside the container
ENV CONFIG=/etc/nipovpn/config.yaml

# Entrypoint runs nipovpn with the chosen mode and config
ENTRYPOINT ["/bin/sh", "-c", "exec /usr/local/bin/nipovpn ${MODE} ${CONFIG}"]
