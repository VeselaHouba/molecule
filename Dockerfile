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
  ansible-lint==5.1.3 \
  docker==5.0.2 \
  flake8==3.9.2 \
  molecule-docker==1.0.2 \
  molecule-hetznercloud==1.3.0 \
  molecule==3.4.0 \
  netaddr \
  pytest-testinfra==6.4.0 \
  yamllint
COPY shellcheck_wrapper.sh /usr/bin/shellcheck_wrapper
