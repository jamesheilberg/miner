# Build stage: build-base
FROM erlang:22-slim as build-base

# Install build dependencies
RUN set -xe \
  && apt-get update \
  && apt-get install -y \
    autoconf \
    automake \
    bison \
    build-essential \
    cmake \
    curl \
    flex \
    git \
    libdbus-1-dev \
    libgmp-dev \
    liblz4-dev \
    libsnappy-dev \
    libsodium-dev \
    libssl-dev \
    libtool \
    pkg-config \
    wget \
  && echo "Done"

# Install Rust toolchain
RUN set -xe \
  && curl https://sh.rustup.rs -sSf | \
    sh -s -- \
      --default-host x86_64-unknown-linux-gnu \
      --default-toolchain stable \
      --profile default \
      -y \
  && echo "Done"

# Build stage: build-dummy
FROM build-base as build-dummy

# Copy our dependency config only
COPY ./rebar* /validator/

# Set workdir
WORKDIR /validator

# Compile dependencies to make things more repeatable
RUN set -xe \
  && . $HOME/.cargo/env \
  && ./rebar3 as docker_val do compile \
  && echo "Done"

# Build stage: build-main
FROM build-dummy as build-main

# Copy project files
COPY . /validator

# Set workdir
WORKDIR /validator

# Build release
RUN ./rebar3 as docker_val do release

RUN set -xe \
  && wget https://github.com/helium/blockchain-etl/raw/master/priv/genesis -O /tmp/genesis -q \
  && echo "b34cfe014f23c88c9d1dd5a1fc4fcecb263d6a98c0708dcd2efe0a15229db76a" /tmp/genesis | sha256sum --check --status \
  && mkdir _build/docker_val/rel/miner/update \
  && mv /tmp/genesis _build/docker_val/rel/miner/update/ \
  && echo "Done"

# Build stage: runtime
FROM erlang:22-slim as runtime

# Install the runtime dependencies
RUN set -xe \
  && apt-get update \
  && apt-get install -y \
    libdbus-1-3 \
    libncurses6 \
    libsnappy1v5 \
    libsodium23 \
    lz4 \
  && echo "Done"

# Install the released application
COPY --from=build-main /validator/_build/docker_val/rel/miner /validator/

# Set workdir
WORKDIR /validator

# Command
CMD /validator/bin/miner foreground