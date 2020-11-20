FROM docker:19-git

RUN apk update && \
  apk add --no-cache \
  bash \
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
  openssh \
  shellcheck
RUN pip3 install \
  wheel
RUN pip3 install \
  ansible==2.10.3 \
  ansible-lint==4.3.7 \
  docker==4.3.1 \
  flake8==3.8.4 \
  molecule-hetznercloud==0.2.2 \
  molecule==3.0.4 \
  netaddr \
  pytest-testinfra==6.1.0
COPY shellcheck_wrapper.sh /usr/bin/shellcheck_wrapper
