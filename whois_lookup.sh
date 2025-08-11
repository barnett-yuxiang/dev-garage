#!/bin/bash
# whois_lookup.sh
# Usage: ./whois_lookup.sh <domain>

if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

whois "$1"
