#!/usr/bin/env bash
BASEURL="https://raw.githubusercontent.com/VeselaHouba/molecule/master/molecule-hetznercloud"
# List scenarios
SCENARIOS="$(find molecule -mindepth 1 -maxdepth 1 -type d)"
for SCENARIO in ${SCENARIOS}; do
  # Static list of files
  for DLFILE in converge.yml create.yml destroy.yml molecule.yml prepare.yml; do
    # Skip if file exists
    DESTFILE="${SCENARIO}/${DLFILE}"
    echo "Checking ${DESTFILE}"
    if [ ! -e ${DESTFILE} ]; then
      echo "${DESTFILE} does not exist, pulling"
      curl "${BASEURL}/${DLFILE}" > "${DESTFILE}"
    fi
  done
done
