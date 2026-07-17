#!/bin/bash

# ========================================================
# Network Access & Proxy Detection Script
# --------------------------------------------------------
# This script checks external network connectivity and
# whether a proxy/VPN is active (useful for verifying
# "scientific internet access").
#
# Checks performed:
#   1. Proxy environment variables
#   2. Public IP & geolocation (via ipinfo.io)
#   3. Domestic connectivity (Baidu)
#   4. International connectivity (Google)
#   5. DNS resolution for Google
#   6. Latency measurement
# ========================================================

TIMEOUT=8
PASS="✅"
FAIL="❌"
WARN="⚠️"
INFO="ℹ️"

divider() {
    echo "──────────────────────────────────────────────────"
}

header() {
    echo ""
    divider
    echo "  $1"
    divider
}

# --------------------------------------------------
# 1. Proxy environment variables
# --------------------------------------------------
header "Proxy Environment Variables"

proxy_set=false
for var in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy; do
    val="${!var}"
    if [ -n "$val" ]; then
        echo "  $PASS $var = $val"
        proxy_set=true
    fi
done

if [ "$proxy_set" = false ]; then
    echo "  $WARN No proxy environment variables detected."
    echo "     Terminal proxy may not be configured."
fi

# --------------------------------------------------
# 2. Public IP & geolocation
# --------------------------------------------------
header "Public IP & Geolocation"

ip_info=$(curl -s --max-time "$TIMEOUT" https://ipinfo.io 2>/dev/null)

if [ -n "$ip_info" ] && echo "$ip_info" | grep -q '"ip"'; then
    ip=$(echo "$ip_info" | grep '"ip"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')
    city=$(echo "$ip_info" | grep '"city"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')
    region=$(echo "$ip_info" | grep '"region"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')
    country=$(echo "$ip_info" | grep '"country"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')
    org=$(echo "$ip_info" | grep '"org"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')

    echo "  $INFO IP       : $ip"
    echo "  $INFO Location : $city, $region, $country"
    echo "  $INFO ISP/Org  : $org"

    if [ "$country" = "CN" ]; then
        echo ""
        echo "  $WARN Exit IP is in China — proxy may NOT be active."
    else
        echo ""
        echo "  $PASS Exit IP is outside China ($country) — proxy appears active."
    fi
else
    echo "  $FAIL Failed to reach ipinfo.io (timeout: ${TIMEOUT}s)"
fi

# --------------------------------------------------
# 3. Domestic connectivity (Baidu)
# --------------------------------------------------
header "Domestic Connectivity (Baidu)"

baidu_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" https://www.baidu.com 2>/dev/null)
baidu_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$TIMEOUT" https://www.baidu.com 2>/dev/null)

if [ "$baidu_code" -ge 200 ] && [ "$baidu_code" -lt 400 ] 2>/dev/null; then
    echo "  $PASS Baidu reachable (HTTP $baidu_code, ${baidu_time}s)"
else
    echo "  $FAIL Baidu unreachable (HTTP $baidu_code)"
    echo "     Basic internet may be down."
fi

# --------------------------------------------------
# 4. International connectivity (Google)
# --------------------------------------------------
header "International Connectivity (Google)"

google_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" https://www.google.com 2>/dev/null)
google_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$TIMEOUT" https://www.google.com 2>/dev/null)

if [ "$google_code" -ge 200 ] && [ "$google_code" -lt 400 ] 2>/dev/null; then
    echo "  $PASS Google reachable (HTTP $google_code, ${google_time}s)"
else
    echo "  $FAIL Google unreachable (HTTP $google_code)"
    echo "     Proxy/VPN may not be working."
fi

youtube_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" https://www.youtube.com 2>/dev/null)

if [ "$youtube_code" -ge 200 ] && [ "$youtube_code" -lt 400 ] 2>/dev/null; then
    echo "  $PASS YouTube reachable (HTTP $youtube_code)"
else
    echo "  $FAIL YouTube unreachable (HTTP $youtube_code)"
fi

# --------------------------------------------------
# 5. DNS resolution check
# --------------------------------------------------
header "DNS Resolution"

if command -v dig &> /dev/null; then
    google_dns=$(dig +short google.com A 2>/dev/null | head -1)
    if [ -n "$google_dns" ]; then
        echo "  $PASS google.com resolved to: $google_dns"
    else
        echo "  $FAIL Failed to resolve google.com — DNS may be polluted."
    fi

    github_dns=$(dig +short github.com A 2>/dev/null | head -1)
    if [ -n "$github_dns" ]; then
        echo "  $PASS github.com resolved to: $github_dns"
    else
        echo "  $FAIL Failed to resolve github.com"
    fi
elif command -v nslookup &> /dev/null; then
    google_dns=$(nslookup google.com 2>/dev/null | grep -A1 "Name:" | grep "Address" | head -1 | awk '{print $2}')
    if [ -n "$google_dns" ]; then
        echo "  $PASS google.com resolved to: $google_dns"
    else
        echo "  $FAIL Failed to resolve google.com"
    fi
else
    echo "  $WARN Neither dig nor nslookup found, skipping DNS check."
fi

# --------------------------------------------------
# 6. Latency summary
# --------------------------------------------------
header "Latency Summary"

measure_latency() {
    local url=$1
    local label=$2
    local time=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$TIMEOUT" "$url" 2>/dev/null)

    if [ -n "$time" ] && [ "$(echo "$time > 0" | bc 2>/dev/null)" = "1" ]; then
        local ms=$(echo "$time * 1000" | bc 2>/dev/null)
        if [ -n "$ms" ]; then
            printf "  %-20s %s ms\n" "$label" "$ms"
        else
            printf "  %-20s %ss\n" "$label" "$time"
        fi
    else
        printf "  %-20s %s\n" "$label" "timeout"
    fi
}

measure_latency "https://www.baidu.com" "Baidu"
measure_latency "https://www.google.com" "Google"
measure_latency "https://github.com" "GitHub"
measure_latency "https://ipinfo.io" "ipinfo.io"

# --------------------------------------------------
# Final verdict
# --------------------------------------------------
header "Verdict"

if [ "$google_code" -ge 200 ] && [ "$google_code" -lt 400 ] 2>/dev/null; then
    echo "  $PASS Proxy/VPN is working — international access OK."
else
    if [ "$baidu_code" -ge 200 ] && [ "$baidu_code" -lt 400 ] 2>/dev/null; then
        echo "  $FAIL Domestic network OK, but international access BLOCKED."
        echo "     → Check your proxy/VPN configuration."
    else
        echo "  $FAIL Network appears to be down entirely."
        echo "     → Check your internet connection first."
    fi
fi

echo ""
