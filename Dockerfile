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
  ansible==2.9.11 \
  ansible-lint==4.3.5 \
  docker==3.7.0 \
  flake8==3.8.3 \
  molecule-hetznercloud==0.2.2 \
  molecule==3.0.6 \
  netaddr \
  testinfra==5.2.2 \
  yamllint
COPY shellcheck_wrapper.sh /usr/bin/shellcheck_wrapper
