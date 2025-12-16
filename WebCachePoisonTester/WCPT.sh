#!/bin/bash

if [ -z "$1" ]; then
  echo "[*] Usage: $0 <URL>"
  exit 1
fi

TARGET_URL="$1"
HEADER_TESTS=("X-Forwarded-Host" "X-Host" "X-Forwarded-Scheme" "X-Rewrite-URL") # Add more headers as needed
PARAM_TESTS=("utm_content" "test_param") # Add more parameters as needed
PAYLOAD="cache-poison-test-$(date +%s)"
TIMEOUT=10
USER_AGENT="Mozilla/5.0 (WebCachePoisonTester)"

TARGET_URL="${TARGET_URL%/}" # Remove trailing slash to maintain consistency.

RESP1=$(mktemp) #
RESP2=$(mktemp)
trap 'rm -f "$RESP1" "$RESP2"' EXIT # When the script exits (for any reason — success, error, or interrupt), run this cleanup command. Not using variables directly for storing responses because it can break binary contents like images, gzip-encoded content responses, etc. Hence, using temp files.

send_request() {
  local url="$1"
  local header="$2"
  local out="$3"
  if [ -n "$header" ]; then
    curl -sS -k -L --max-time "$TIMEOUT" -A "$USER_AGENT" -H "$header" -o "$out" "$url"
  else
    curl -sS -k -L --max-time "$TIMEOUT" -A "$USER_AGENT" -o "$out" "$url"
  fi
}

# Test headers
echo "[*] Testing header-based cache poisoning..."
for header in "${HEADER_TESTS[@]}"; do
  echo "[*] Testing header: $header"
  send_request "$TARGET_URL" "$header: $PAYLOAD" "$RESP1"
  send_request "$TARGET_URL" "" "$RESP2"
  if cmp -s "$RESP1" "$RESP2"; then # Check if the responses are the same to confirm caching because of the following unkeyed header.
    echo "[+] VULNERABLE via $header"
  else
    echo "[-] Not vulnerable via $header"
  fi
done

# Parse URL for parameter testing
proto=$(echo "$TARGET_URL" | grep :// | sed 's|://.*||') # Matches everything up to and including the :// in the URL and removes it so that the protocol is left.
if [ -z "$proto" ]; then
  echo "[-] Error: Invalid URL"
  exit 1
fi
url_without_proto="${TARGET_URL#*://}" # Matches everything up to and including the :// in the URL and removes it so that the host and path are left.
host_port="${url_without_proto%%/*}" # Matches everything up to and including the first / in the URL and removes it so that the host is left and also the port if any.
if [ "$host_port" = "$url_without_proto" ]; then
  path=""
else
  path="${url_without_proto#*/}" # Matches everything after the first / in the URL and removes it so that the path is left.
fi

echo ""
echo "[*] Testing parameter-based cache poisoning..."
for param in "${PARAM_TESTS[@]}"; do
  echo "[*] Testing parameter: $param"
  if [ -z "$path" ]; then # Check if the path is empty
    test_url="${proto}://${host_port}?$param=$PAYLOAD"
  elif echo "$path" | grep -q '?'; then # Check if the path contains a query string
    test_url="${proto}://${host_port}/${path}&$param=$PAYLOAD" # Add our test parameter to the existing query string. So, two query strings are passed.
  else # Path does not contain a query string
    test_url="${proto}://${host_port}/${path}?$param=$PAYLOAD" # Add only our test parameter to the existing path. So, a single query string is passed.
  fi

  send_request "$test_url" "" "$RESP1"
  send_request "$TARGET_URL" "" "$RESP2"
  if cmp -s "$RESP1" "$RESP2"; then # Check if the responses are the same to confirm caching because of the following unkeyed parameter.
    echo "[+] VULNERABLE via $param"
  else
    echo "[-] Not vulnerable via $param"
  fi
done

echo ""
echo "[+] Scan completed. Note: Make sure to verify findings manually."
