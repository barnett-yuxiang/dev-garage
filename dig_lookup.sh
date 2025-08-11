#!/bin/bash
# domain_lookup.sh
# Usage: ./domain_lookup.sh <domain>

if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

dig +noall +answer "$1"
