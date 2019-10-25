FROM docker:git

RUN apk update && \
  apk add --no-cache \
  docker \
  python3-dev \
  py3-pip \
  docker \
  gcc \
  git \
  curl \
  build-base \
  autoconf \
  automake \
  py3-cryptography \
  linux-headers \
  musl-dev \
  libffi-dev \
  openssl-dev \
  openssh
RUN pip3 install ansible==2.8.6 molecule==2.22 docker==3.7.0
