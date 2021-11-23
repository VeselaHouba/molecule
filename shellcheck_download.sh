#!/usr/bin/env bash
case "${TARGETARCH}" in
  amd64 ) ARCH=x86_64 ;;
  arm64 ) ARCH=aarch64 ;;
  * ) ARCH=x86_64 ;;
esac
wget -qO /tmp/shellcheck-stable.linux.${ARCH}.tar.xz https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.${ARCH}.tar.xz && \
tar xf /tmp/shellcheck-stable.linux.${ARCH}.tar.xz --strip-components 1 -C /usr/bin/ shellcheck-stable/shellcheck && \
rm -f /tmp/shellcheck-stable.linux.${ARCH}.tar.xz
