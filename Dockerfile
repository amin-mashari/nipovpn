FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ca-certificates git wget \
    libssl-dev libyaml-cpp-dev libboost-all-dev openssl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy source
COPY . .

# Build the project
RUN mkdir -p build && cd build \
  && cmake .. \
  && make -j$(nproc)

# Install runtime artifacts
RUN mkdir -p /etc/nipovpn /var/log/nipovpn \
  && find . -type f -name nipovpn -executable -print -exec cp {} /usr/local/bin/nipovpn \; || true

# Default config shipped with package (can be overridden by volume)
COPY nipovpn/etc/nipovpn/config.yaml /etc/nipovpn/config.yaml

# Entrypoint for runtime SSL generation
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/bin/nipovpn"]
