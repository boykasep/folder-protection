# 🗂️ Automated .htaccess Protection Script

A powerful Bash script for system administrators to automatically secure a large number of subdirectories. It automates the tedious process of creating individual `.htaccess` and `.htpasswd` files for each folder, applying strong, unique passwords using security best practices.

## ✨ Core Features

-   **✅ Bulk Security Automation:** Scans a parent directory and applies protection to all its subdirectories automatically.
-   **✅ Security Best Practices:** Stores `.htpasswd` files outside the public web root and saves credentials in a separate, secure location with restricted permissions (`600`).
-   **✅ Strong, Cryptographically Secure Passwords:** Uses `/dev/urandom` to generate strong, unpredictable passwords for each directory.
-   **✅ Robust and Safe:** Correctly handles folder names with **spaces and special characters** by sanitizing them for use as usernames.
-   **✅ Professional Logging:** A modular, colored logging system (`INFO`, `WARN`, `ERROR`) provides clear feedback.

## 🔧 Prerequisites

-   A Unix-like environment (Linux is ideal).
-   `apache2-utils` must be installed for the `htpasswd` command.

## ⚙️ Configuration

Before running, you **must** edit the configuration variables at the top of the `secure-folders.sh` script.

## 🚀 Usage

1.  Configure the script as described above.
2.  Make it executable: `chmod +x secure-folders.sh`.
3.  Run it: `./secure-folders.sh`.

**⚠️ WARNING:** This script performs powerful operations. Always test it on a non-production directory first.

---
*Concept and original script by boykasep. Refactored for public release with assistance from Google's Gemini.*
