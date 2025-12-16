# Web Cache Poisoning Checker

A lightweight Bash script to detect potential web cache poisoning vulnerabilities by testing if a web application's cache treats requests with unkeyed inputs (headers or URL parameters) identically to normal requests.

## 📌 Overview

This tool checks for **cache poisoning** by:
- Sending requests with unique values in **common unkeyed headers** (e.g., `X-Host`, `X-Forwarded-Host`)
- Sending requests with unique values in **common unkeyed parameters** (e.g., `utm_content`, `test_param`)
- Comparing responses to the original request  
✅ If responses are **identical**, the cache may be **vulnerable** — because it ignored the injected input while the application might have processed it.

> ⚠️ **Note**: This is a detection heuristic. **Always manually verify** any reported findings.

## 🛠️ Requirements

- `bash`
- `curl`
- `grep`
- `cmp` (usually pre-installed)

Tested on Linux and macOS.

## 🚀 Usage

```bash
chmod +x WCPT.sh
./WCPT.sh https://example.com

## Test Lab:
Link: https://portswigger.net/web-security/web-cache-poisoning/exploiting-design-flaws/lab-web-cache-poisoning-with-an-unkeyed-header
