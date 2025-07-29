#!/usr/bin/env bash

# =============================================================================
# Automated .htaccess Protection Script v2.0 - Open Public Using 
# =============================================================================

# === [ CONFIGURATION ] ===
WEB_ROOT_DIR="/var/www/html/protected_files"
HTPASSWD_DIR="/etc/apache2/htpasswds/protected_files"
CREDENTIALS_DIR="/var/secure_data/passwords"
LOG_FILE="/var/log/secure_setup.log"
PASSWORD_LENGTH=12
HASHING_ALGO="-B" # -B for Bcrypt (recommended), -bm for MD5 (legacy)
# ========================

set -euo pipefail

# --- ANSI Color Codes for Logging ---
COLOR_RESET='\033[0m'; COLOR_RED='\033[0;31m'; COLOR_GREEN='\033[0;32m';
COLOR_YELLOW='\033[0;33m';

log() {
    local level="$1" message="$2" color="$COLOR_RESET"
    case "$level" in
        INFO) color="$COLOR_GREEN" ;; WARN) color="$COLOR_YELLOW" ;;
        ERROR) color="$COLOR_RED" ;;
    esac
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${color}[${timestamp}] [${level}] ${message}${COLOR_RESET}" | tee -a "$LOG_FILE" >&2
}

exit_with_error() {
    log "ERROR" "$1"
    exit 1
}

# --- Core Functions ---
check_dependencies() {
    command -v htpasswd >/dev/null || exit_with_error "'htpasswd' not found. Please install 'apache2-utils'."
}

check_directories() {
    for dir in "$WEB_ROOT_DIR" "$HTPASSWD_DIR" "$CREDENTIALS_DIR"; do
        mkdir -p "$dir" || exit_with_error "Could not create directory: $dir"
        [[ -w "$dir" ]] || exit_with_error "Directory is not writable: $dir"
        chmod 755 "$dir"
    done
}

generate_random_password() {
    local upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lower="abcdefghijklmnopqrstuvwxyz"
    local digit="0123456789"
    local symbol='!@#$%^&*'
    local all="${upper}${lower}${digit}${symbol}"
    local pass=""
    pass+=$(LC_ALL=C tr -dc "$upper" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$lower" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$digit" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$symbol" < /dev/urandom | head -c 1)
    pass+=$(LC_ALL=C tr -dc "$all" < /dev/urandom | head -c $((PASSWORD_LENGTH - 4)))
    echo "$pass" | fold -w1 | shuf | tr -d '\n'
}

process_subfolder() {
    local folder_name="$1"
    
    # KEY IMPROVEMENT: Sanitize folder name for use as username and filename
    local sanitized_name
    sanitized_name=$(echo "$folder_name" | tr -d '[:space:]' | tr -c '[:alnum:]_.-' '_')
    local username="$sanitized_name"
    
    if [[ -z "$username" ]]; then
        log "WARN" "Skipping folder with invalid name: '$folder_name'"
        return
    fi

    local base_path="$WEB_ROOT_DIR/$folder_name"
    local htpasswd_dir="$HTPASSWD_DIR/$sanitized_name"
    local htpasswd_file="$htpasswd_dir/passwd"
    local htaccess_file="$base_path/.htaccess"
    local credentials_file="$CREDENTIALS_DIR/password_$username"

    mkdir -p "$htpasswd_dir"
    
    local password
    password=$(generate_random_password)

    if ! htpasswd -c -b "${HASHING_ALGO}" "$htpasswd_file" "$username" "$password" 2>>"$LOG_FILE"; then
        log "WARN" "Failed to create htpasswd for '$username', skipping."
        return
    fi
    chmod 644 "$htpasswd_file"

    cat > "$htaccess_file" <<EOF
AuthType Basic
AuthName "Protected Area"
AuthUserFile $htpasswd_file
Require valid-user
EOF
    chmod 644 "$htaccess_file"

    echo "Username: $username" > "$credentials_file"
    echo "Password: $password" >> "$credentials_file"
    chmod 600 "$credentials_file"

    log "INFO" "-> ✓ Protection enabled for: '$folder_name' (user: '$username')"
}

# --- Main Execution ---
main() {
    echo "" >> "$LOG_FILE" # Separator for new run
    log "INFO" "========== Starting Protection Setup =========="
    check_dependencies
    check_directories

    local found_folders=false
    while IFS= read -r -d '' subfolder_path; do
        found_folders=true
        local subfolder_name
        subfolder_name=$(basename -- "$subfolder_path")
        log "INFO" "Processing subfolder: '$subfolder_name'"
        process_subfolder "$subfolder_name"
    done < <(find "$WEB_ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if ! $found_folders; then
        log "WARN" "No subfolders found in '$WEB_ROOT_DIR' to protect."
    fi

    log "INFO" "========== All operations completed =========="
}

main "$@"
