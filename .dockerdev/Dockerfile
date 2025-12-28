ARG RUBY_VERSION=3.4.2
FROM ruby:$RUBY_VERSION-slim

# Development tools
RUN apt-get update -qq && apt-get install -y \
    build-essential git libpq-dev libyaml-dev pkg-config \
    curl nodejs npm postgresql-client libvips vim unzip \
    && rm -rf /var/lib/apt/lists/*

# Install watchman (required by Tailwind CSS v4 for watch mode)
ARG WATCHMAN_VERSION=v2024.11.04.00
RUN cd /tmp && \
    curl -LO https://github.com/facebook/watchman/releases/download/${WATCHMAN_VERSION}/watchman-${WATCHMAN_VERSION}-linux.zip && \
    unzip watchman-${WATCHMAN_VERSION}-linux.zip && \
    cd watchman-${WATCHMAN_VERSION}-linux && \
    mkdir -p /usr/local/bin /usr/local/lib /usr/local/var/run/watchman && \
    cp bin/* /usr/local/bin/ && \
    cp lib/* /usr/local/lib/ && \
    chmod 755 /usr/local/bin/watchman && \
    chmod 2777 /usr/local/var/run/watchman && \
    cd / && rm -rf /tmp/watchman*

WORKDIR /app

# Bundler settings for development (faster installs)
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Install foreman for Procfile.dev
RUN gem install foreman

# Keep container running for interactive use
CMD ["sleep", "infinity"]
