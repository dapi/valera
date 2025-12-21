ARG RUBY_VERSION=3.4.2
FROM ruby:$RUBY_VERSION-slim

# Development tools
RUN apt-get update -qq && apt-get install -y \
    build-essential git libpq-dev libyaml-dev pkg-config \
    curl nodejs npm postgresql-client libvips vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bundler settings for development (faster installs)
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Install foreman for Procfile.dev
RUN gem install foreman

# Keep container running for interactive use
CMD ["sleep", "infinity"]
