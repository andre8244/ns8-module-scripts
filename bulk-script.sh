#!/bin/bash

# This script is used to invoke a script on multiple NS8 modules, e.g., for applying a CVE fix on several repositories at once.

set -e

SCRIPT="axios-CVE-2025-27152.sh"

REPOS=(
  "NethServer/ns8-kickstart"
  "NethServer/ns8-nethvoice"
  "NethServer/ns8-mail"
)

# invoke script multiple times with different repositories
for REPO in "${REPOS[@]}"; do
  echo "Processing repository: $REPO"
  bash ./"$SCRIPT" "$REPO"
  # print a newline for better readability
  echo
done
