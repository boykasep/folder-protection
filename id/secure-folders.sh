#!/usr/bin/env bash

# =============================================================================
# Skrip Proteksi .htaccess Otomatis v3.0 - Edisi Publikasi Terbuka untuk umum
# =============================================================================

# === [ KONFIGURASI ] ===
WEB_ROOT_DIR="/var/www/html/file_terproteksi"
HTPASSWD_DIR="/etc/apache2/htpasswds/file_terproteksi"
CREDENTIALS_DIR="/var/data_aman/passwords"
LOG_FILE="/var/log/setup_keamanan.log"
PASSWORD_LENGTH=12
HASHING_ALGO="-B"
# ========================

set -euo pipefail

# --- Kode Warna ANSI ---
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

# --- Fungsi Inti ---
check_dependencies() {
    command -v htpasswd >/dev/null || exit_with_error "'htpasswd' tidak ditemukan. Silakan install 'apache2-utils'."
}

check_directories() {
    for dir in "$WEB_ROOT_DIR" "$HTPASSWD_DIR" "$CREDENTIALS_DIR"; do
        mkdir -p "$dir" || exit_with_error "Tidak dapat membuat direktori: $dir"
        [[ -w "$dir" ]] || exit_with_error "Direktori tidak dapat ditulisi: $dir"
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
    
    # PERBAIKAN KUNCI: Sanitasi nama folder untuk digunakan sebagai username dan nama file
    local sanitized_name
    sanitized_name=$(echo "$folder_name" | tr -d '[:space:]' | tr -c '[:alnum:]_.-' '_')
    local username="$sanitized_name"
    
    if [[ -z "$username" ]]; then
        log "WARN" "Melewati folder dengan nama tidak valid: '$folder_name'"
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
        log "WARN" "Gagal membuat htpasswd untuk '$username', melewati folder ini."
        return
    fi
    chmod 644 "$htpasswd_file"

    cat > "$htaccess_file" <<EOF
AuthType Basic
AuthName "Area Terproteksi"
AuthUserFile $htpasswd_file
Require valid-user
EOF
    chmod 644 "$htaccess_file"

    echo "Username: $username" > "$credentials_file"
    echo "Password: $password" >> "$credentials_file"
    chmod 600 "$credentials_file"

    log "INFO" "-> ✓ Proteksi aktif untuk: '$folder_name' (user: '$username')"
}

# --- Eksekusi Utama ---
main() {
    echo "" >> "$LOG_FILE" # Pemisah untuk eksekusi baru
    log "INFO" "========== Memulai Setup Proteksi =========="
    check_dependencies
    check_directories

    local found_folders=false
    while IFS= read -r -d '' subfolder_path; do
        found_folders=true
        local subfolder_name
        subfolder_name=$(basename -- "$subfolder_path")
        log "INFO" "Memproses subfolder: '$subfolder_name'"
        process_subfolder "$subfolder_name"
    done < <(find "$WEB_ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if ! $found_folders; then
        log "WARN" "Tidak ada subfolder yang ditemukan di '$WEB_ROOT_DIR' untuk diproteksi."
    fi

    log "INFO" "========== Semua operasi selesai =========="
}

main "$@"
