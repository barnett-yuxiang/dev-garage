#!/bin/bash
# reverse_lookup.sh
# Usage: ./reverse_lookup.sh <ip>

if [ -z "$1" ]; then
  echo "Usage: $0 <ip>"
  exit 1
fi

dig +noall +answer -x "$1"
