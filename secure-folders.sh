#!/usr/bin/env bash

# =============================================================================
# Automated .htaccess Protection Script (v2.0 - Public Release)
# Description: A script to bulk-apply .htaccess password protection to numerous
#              subdirectories, using security best practices.
# =============================================================================

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

set -euo pipefail

log() {
    # Logs message to both console and log file
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

exit_with_error() {
    log "❌ ERROR: $1"
    exit 1
}

# --- Core Functions ---

check_dependencies() {
    command -v htpasswd >/dev/null || exit_with_error "'htpasswd' not found. Please install 'apache2-utils'."
}

check_directories() {
    for dir in "$WEB_ROOT_DIR" "$HTPASSWD_DIR" "$CREDENTIALS_DIR"; do
        if ! mkdir -p "$dir"; then
            exit_with_error "Could not create directory: $dir"
        fi
        if ! [[ -w "$dir" ]]; then
            exit_with_error "Directory is not writable: $dir"
        fi
        chmod 755 "$dir"
    done
}

# Cryptographically secure password generation
generate_random_password() {
    local upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lower="abcdefghijklmnopqrstuvwxyz"
    local digit="0123456789"
    local symbol='!@#$%^&*' # Use single quotes for safety
    local all="${upper}${lower}${digit}${symbol}"

    # Ensure at least one of each character type
    local pass=""
    pass+=$(LC_ALL=C tr -dc "$upper" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$lower" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$digit" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$symbol" < /dev/urandom | head -c 1)

    # Add remaining characters randomly
    pass+=$(LC_ALL=C tr -dc "$all" < /dev/urandom | head -c $((PASSWORD_LENGTH - 4)))

    # Shuffle the resulting password to randomize character order
    echo "$pass" | fold -w1 | shuf | tr -d '\n'
}

process_subfolder() {
    local folder_name="$1"
    local base_path="$WEB_ROOT_DIR/$folder_name"
    local htpasswd_dir="$HTPASSWD_DIR/$folder_name"
    local htpasswd_file="$htpasswd_dir/passwd"
    local htaccess_file="$base_path/.htaccess"
    local credentials_file="$CREDENTIALS_DIR/password_${folder_name//\//_}" # Sanitize slashes in folder name

    mkdir -p "$htpasswd_dir"
    chmod 755 "$htpasswd_dir"

    # Backup existing files just in case
    [[ -f "$htpasswd_file" ]] && cp "$htpasswd_file" "$htpasswd_file.bak"
    [[ -f "$htaccess_file" ]] && cp "$htaccess_file" "$htaccess_file.bak"

    local username="$folder_name"
    local password
    password=$(generate_random_password)

    # Create the htpasswd file with the chosen algorithm
    if ! htpasswd -c -b "${HASHING_ALGO}" "$htpasswd_file" "$username" "$password" 2>>"$LOG_FILE"; then
        log "   -> ⚠️ Failed to create htpasswd for '$username', skipping."
        return
    fi
    chmod 644 "$htpasswd_file"

    # Create the .htaccess file
    cat > "$htaccess_file" <<EOF
AuthType Basic
AuthName "Protected Area"
AuthUserFile $htpasswd_file
Require valid-user
EOF
    chmod 644 "$htaccess_file"

    # Store the credentials securely
    echo "Username: $username" > "$credentials_file"
    echo "Password: $password" >> "$credentials_file"
    chmod 600 "$credentials_file"

    log "   -> ✓ Protection enabled for: $folder_name"
}

# --- Main Execution ---
main() {
    echo "========== Starting Protection Setup: $(date) ==========" >> "$LOG_FILE"
    log "INFO: Starting dependency and directory checks..."
    check_dependencies
    check_directories
    log "INFO: Checks passed. Starting to process folders."

    # KEY IMPROVEMENT: Use find -print0 and while read for safety with all folder names
    local found_folders=false
    while IFS= read -r -d '' subfolder_path; do
        found_folders=true
        local subfolder_name
        subfolder_name=$(basename -- "$subfolder_path")
        
        log "Processing subfolder: '$subfolder_name'"
        process_subfolder "$subfolder_name"
        
    done < <(find "$WEB_ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if ! $found_folders; then
        log "⚠️ WARNING: No subfolders found in '$WEB_ROOT_DIR' to protect."
    fi

    log "✅ All operations completed: $(date)"
}

main "$@"
