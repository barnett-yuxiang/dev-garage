#!/bin/bash
# dig_lookup.sh
# Usage: ./dig_lookup.sh <domain>

if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

dig +noall +answer "$1"
