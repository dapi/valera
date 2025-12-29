# Ubuntu 24.04 for GLIBC 2.39 compatibility with watchman
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Development tools and Ruby runtime dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential git libpq-dev libyaml-dev pkg-config \
    curl nodejs npm postgresql-client libvips vim unzip \
    libssl-dev libreadline-dev zlib1g-dev libffi-dev libjemalloc2 \
    && rm -rf /var/lib/apt/lists/*

# Install prebuilt Ruby from ruby-builder (fast!)
# Note: Archive contains latest patch version (e.g., 3.4.x)
ARG RUBY_VERSION=3.4.2
RUN mkdir -p /opt/ruby && \
    curl -fsSL "https://github.com/ruby/ruby-builder/releases/download/toolcache/ruby-${RUBY_VERSION}-ubuntu-24.04.tar.gz" \
    | tar xz -C /opt/ruby --strip-components=1 && \
    echo "/opt/ruby/lib" > /etc/ld.so.conf.d/ruby.conf && \
    ldconfig && \
    # Create symlink for Ruby's hardcoded paths (built for GitHub Actions)
    # Extract actual Ruby version from binary
    ACTUAL_VERSION=$(/opt/ruby/bin/ruby -e 'puts RUBY_VERSION') && \
    mkdir -p /opt/hostedtoolcache/Ruby/${ACTUAL_VERSION} && \
    ln -s /opt/ruby /opt/hostedtoolcache/Ruby/${ACTUAL_VERSION}/x64

ENV PATH="/opt/ruby/bin:$PATH"
SHELL ["/bin/bash", "-c"]

# Install watchman (required by Tailwind CSS v4 for watch mode)
ARG WATCHMAN_VERSION=v2025.12.22.00
RUN cd /tmp && \
    curl -LO https://github.com/facebook/watchman/releases/download/${WATCHMAN_VERSION}/watchman-${WATCHMAN_VERSION}-linux.zip && \
    unzip watchman-${WATCHMAN_VERSION}-linux.zip && \
    cd watchman-${WATCHMAN_VERSION}-linux && \
    mkdir -p /usr/local/bin /usr/local/lib /usr/local/var/run/watchman && \
    cp bin/* /usr/local/bin/ && \
    cp lib/* /usr/local/lib/ && \
    chmod 755 /usr/local/bin/watchman && \
    chmod 2777 /usr/local/var/run/watchman && \
    ldconfig && \
    cd / && rm -rf /tmp/watchman*

WORKDIR /app

# Bundler settings for development
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Install foreman
RUN gem install foreman

CMD ["sleep", "infinity"]
