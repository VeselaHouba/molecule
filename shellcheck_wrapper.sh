#!/usr/bin/env sh
for file in $(find . -type f -name "*.sh"); do
  shellcheck --format=gcc $file
done
