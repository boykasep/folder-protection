# 🗂️ Skrip Proteksi .htaccess Otomatis

Sebuah skrip Bash yang andal untuk administrator sistem guna mengamankan banyak subdirektori di dalam struktur file server web secara otomatis. Skrip ini mengotomatiskan proses membosankan dalam membuat file `.htaccess` dan `.htpasswd` individual untuk setiap folder, dengan menerapkan kata sandi yang kuat dan unik.

Skrip ini lahir dari kebutuhan nyata untuk melindungi ratusan folder dokumen wisudawan, mengubah pekerjaan manual berjam-jam menjadi satu perintah tunggal yang andal.

## ✨ Fitur Inti

-   **✅ Otomatisasi Keamanan Massal:** Memindai direktori induk dan menerapkan proteksi ke semua subdirektorinya secara otomatis.
-   **✅ Praktik Keamanan Terbaik:** Menyimpan file `.htpasswd` di luar *web root* publik dan menyimpan kredensial di lokasi terpisah yang aman dengan izin terbatas (`600`).
-   **✅ Kata Sandi Kuat & Aman:** Menggunakan `/dev/urandom` untuk menghasilkan kata sandi yang kuat dan tidak dapat diprediksi untuk setiap direktori, memastikan adanya campuran jenis karakter.
-   **✅ Aman dan Tangguh:** Menangani nama folder dengan **spasi dan karakter khusus** dengan benar serta menyertakan pengecekan awal untuk dependensi dan izin direktori.
-   **✅ Pencatatan Log Detail:** Semua aksi dicatat ke dalam file log untuk keperluan audit dan peninjauan.

## 🔧 Prasyarat

-   Lingkungan berbasis Unix (Linux sangat ideal).
-   `apache2-utils` (atau yang setara) harus terinstal untuk menyediakan perintah `htpasswd`.
    -   Di Debian/Ubuntu, instal dengan: `sudo apt update && sudo apt install apache2-utils`

## ⚙️ Konfigurasi

Sebelum menjalankan, Anda **wajib** mengubah variabel konfigurasi di bagian atas skrip `amankan-folder.sh`:

```bash
# === [ KONFIGURASI ] ===
# Direktori utama yang berisi subfolder yang akan diproteksi (contoh: /var/www/html/wisudawan)
WEB_ROOT_DIR="/var/www/html/file_terproteksi"

# Direktori aman di LUAR web root untuk menyimpan file .htpasswd
HTPASSWD_DIR="/etc/apache2/htpasswds/file_terproteksi"

# Direktori aman untuk menyimpan kata sandi plain-text yang dihasilkan (izin akan diatur ke 600)
CREDENTIALS_DIR="/var/data_aman/passwords"

# Lokasi file log
LOG_FILE="/var/log/setup_keamanan.log"

# Panjang kata sandi dan algoritma hashing untuk htpasswd (-B untuk Bcrypt disarankan)
PASSWORD_LENGTH=12
HASHING_ALGO="-B" # Gunakan -bm untuk MD5 di sistem lama
# ========================

# Sedikit dari saudaramu boykasep, semoga bermanfaat yaah

