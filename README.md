# 🗂️ Automated .htaccess Protection Script

A powerful Bash script for system administrators to automatically secure a large number of subdirectories within a web server's file structure. It automates the tedious process of creating individual `.htaccess` and `.htpasswd` files for each folder, applying strong, unique passwords.

This script was born from a real-world need to protect hundreds of individual graduate document folders, turning a multi-hour manual task into a single, reliable command.

## ✨ Core Features

-   **✅ Bulk Security Automation:** Scans a parent directory and applies protection to all its subdirectories automatically.
-   **✅ Security Best Practices:** Stores `.htpasswd` files outside the public web root and saves credentials in a separate, secure location with restricted permissions (`600`).
-   **✅ Strong, Cryptographically Secure Passwords:** Uses `/dev/urandom` to generate strong, unpredictable passwords for each directory, ensuring a mix of character types.
-   **✅ Safe and Robust:** Handles folder names with **spaces and special characters** correctly and includes pre-flight checks for dependencies and directory permissions.
-   **✅ Detailed Logging:** All actions are logged to a file for auditing and review.

## 🔧 Prerequisites

-   A Unix-like environment (Linux is ideal).
-   `apache2-utils` (or equivalent) must be installed to provide the `htpasswd` command.
    -   On Debian/Ubuntu, install with: `sudo apt update && sudo apt install apache2-utils`

## ⚙️ Configuration

Before running, you **must** edit the configuration variables at the top of the `secure-folders.sh` script:

```bash
# === [ CONFIGURATION ] ===
# The main directory containing the subfolders to be protected (e.g., /var/www/html/graduates)
WEB_ROOT_DIR="/var/www/html/protected_files"

# Secure directory OUTSIDE the web root to store the .htpasswd files
HTPASSWD_DIR="/etc/apache2/htpasswds/protected_files"

# Secure directory to save the generated plain-text passwords (permissions will be set to 600)
CREDENTIALS_DIR="/var/secure_data/passwords"

# Log file location
LOG_FILE="/var/log/secure_setup.log"

# Password length and hashing algorithm for htpasswd (-B for Bcrypt is recommended)
PASSWORD_LENGTH=12
HASHING_ALGO="-B" # Use -bm for MD5 on older systems
# ========================
