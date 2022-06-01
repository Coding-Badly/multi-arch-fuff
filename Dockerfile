FROM ubuntu:22.04
MAINTAINER Gremlin Inc.

RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y \
    apt-transport-https \
    automake \
    ca-certificates \
    curl \
    wget \
  && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y tzdata \
  && apt-get install -y software-properties-common \
  && apt-get update \
  && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    sudo \
  && sudo mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update \
# Do we need all that?  We'll assume "no".
# && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  && sudo apt-get install -y \
    docker-ce \
    skopeo \
    musl-tools \
    golang-go \
    go-md2man \
    make \
    nano \
# Do we need all that?  We'll assume "no".
#    cmake \
#    cron \
#    curl \
#    file \
#    git \
#    g++ \
#    iproute2 \
#    man \
#    sudo \
#    screen \
#    dnsutils \
#    iputils-ping \
#    net-tools \
#    vim \
#    ca-certificates \
#    xz-utils \
#    pkg-config \
#    apt-file \
#    xutils-dev \
  && rm -rf /var/lib/apt/lists/*

####################################################################################################

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/cargo/bin:$PATH \
    RUST_VERSION=1.58.1

RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y \
	--default-toolchain $RUST_VERSION \
	--no-modify-path \
	--component rustfmt llvm-tools-preview \
  && rustup toolchain install nightly --profile=minimal --component rustfmt \
  && rustup target add $(uname -m)-unknown-linux-musl \
  && rustup +nightly target add $(uname -m)-unknown-linux-musl \
  && mkdir /.cargo \
  && echo "[build]\ntarget = \"$(uname -m)-unknown-linux-musl\"" > /.cargo/config

ENV CARGO_HOME="/cargo"

RUN cargo +nightly install grcov --version 0.8.4 # https://github.com/mozilla/grcov/issues/763

####################################################################################################

ENV GOPATH=/home/ubuntu/go

ENV OLDGO_VERSION=1.13.8

ENV OLDGO=${GOPATH}/bin/go${OLDGO_VERSION}

RUN go install golang.org/dl/go${OLDGO_VERSION}@latest \
  && $OLDGO download

RUN export NEWGO=$(which go) \
  && mv $NEWGO $NEWGO-set-aside \
  && ln -s $OLDGO $NEWGO \
  && go get -d github.com/opencontainers/image-tools/cmd/oci-image-tool \
  && cd $GOPATH/src/github.com/opencontainers/image-tools/ \
  && make all \
  && sudo make install \
  && go get -d github.com/opencontainers/runtime-tools/cmd/oci-runtime-tool \
  && cd $GOPATH/src/github.com/opencontainers/runtime-tools/ \
  && make all \
  && sudo make install \
  && rm $NEWGO \
  && mv $NEWGO-set-aside $NEWGO
