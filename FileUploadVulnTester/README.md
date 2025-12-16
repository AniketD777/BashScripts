# File Upload Vulnerability Tester

A Bash script to test for insecure file upload functionality by attempting to upload harmless PHP-based test files with dangerous extensions and checking if they are accessible and executed.

Designed to work with authenticated uploads (e.g., PortSwigger Web Security Academy labs) that require:
- Session cookies
- CSRF tokens
- Additional form fields (e.g., `user=wiener`)

---

## ✅ Features

- Supports **authenticated uploads** via session cookie
- Automatically **extracts CSRF token** from account page
- Tests multiple **dangerous PHP extensions** (`.php`, `.phtml`, etc.)
- Validates payload execution by checking for expected output
- Uses **temporary files** for safe payload handling
- Works with labs requiring extra form fields (e.g., `user=wiener`)

---

## 🛠️ Requirements

- `bash`
- `curl`
- `grep`
- `sed`

Tested on Linux and macOS.

---

## 🚀 Usage

```bash
chmod +x FUVT.sh
./FUVT.sh <upload-url> <uploaded-files-base-url> [session-cookie]

## Test Lab:
Link: https://portswigger.net/web-security/file-upload/lab-file-upload-remote-code-execution-via-web-shell-upload
