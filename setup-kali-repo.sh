#!/bin/sh
# setup-kali-repo.sh
# Menambahkan repo Kali Linux ke Debian dengan APT pinning (aman, tidak overwrite Debian base)
# Usage: sudo sh setup-kali-repo.sh

set -e

KEYRING="/usr/share/keyrings/kali-archive-keyring.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/kali.list"
PREF_FILE="/etc/apt/preferences.d/kali.pref"

# --- Cek root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Script ini harus dijalankan sebagai root (pakai sudo)."
    exit 1
fi

echo "[*] Cek dependency (wget, gpg)..."
for bin in wget gpg; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "[!] '$bin' belum terinstall. Install dulu: apt install $bin"
        exit 1
    fi
done

# --- 1. Tambah GPG Key Kali ---
echo "[*] Menambahkan GPG key Kali Linux..."
wget -q -O - https://archive.kali.org/archive-key.asc | gpg --dearmor -o "$KEYRING"

if [ -f "$KEYRING" ]; then
    echo "[+] GPG key berhasil disimpan di $KEYRING"
else
    echo "[!] Gagal menyimpan GPG key."
    exit 1
fi

# --- 2. Buat source list Kali ---
echo "[*] Membuat source list Kali di $SOURCE_LIST..."
cat > "$SOURCE_LIST" << EOF
# See https://www.kali.org/docs/general-use/kali-linux-sources-list-repositories/
deb [signed-by=$KEYRING] https://http.kali.org/kali kali-rolling main non-free non-free-firmware contrib

# Additional line for source packages
deb-src [signed-by=$KEYRING] https://http.kali.org/kali kali-rolling main non-free non-free-firmware contrib
EOF

echo "[+] Source list dibuat."

# --- 3. Buat file pinning ---
echo "[*] Membuat file pinning di $PREF_FILE..."
cat > "$PREF_FILE" << EOF
Package: *
Pin: release a=kali-rolling
Pin-Priority: 50
EOF

echo "[+] Pinning dibuat (priority 50 -> Kali tidak akan menimpa Debian secara otomatis)."

# --- 4. Update ---
echo "[*] Menjalankan apt update..."
apt update

echo ""
echo "======================================================"
echo " Setup selesai."
echo "======================================================"
echo ""
echo "CARA PAKAI:"
echo ""
echo "1. Cek asal paket sebelum install:"
echo "   apt-cache policy <nama-paket>"
echo ""
echo "2. Install paket DARI KALI (wajib pakai -t):"
echo "   sudo apt install -t kali-rolling <nama-paket>"
echo ""
echo "3. Simulasikan dulu sebelum eksekusi (WAJIB dicek):"
echo "   sudo apt install -t kali-rolling <nama-paket> --simulate"
echo "   -> Kalau muncul paket base system (glibc/libc6/systemd), JANGAN lanjut."
echo ""
echo "4. Ambil source code paket (butuh deb-src, contoh untuk build manual):"
echo "   apt-get source <nama-paket>"
echo ""
echo "5. JANGAN PERNAH jalankan tanpa cek dulu:"
echo "   sudo apt full-upgrade / sudo apt dist-upgrade"
echo "   -> Cek dulu dengan: apt list --upgradable"
echo ""
echo "6. Uninstall paket seperti biasa:"
echo "   sudo apt remove <nama-paket>"
echo ""
