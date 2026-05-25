#!/bin/bash
# setup.sh — Inisialisasi bucket, quota, dan policy per mahasiswa
# Jalankan setelah: docker compose up -d

set -e

SERVER="http://localhost"
QUOTA="5GiB"

USERS=(
  "mahasiswa-a:PasswordA123!:9100"
  "mahasiswa-b:PasswordB123!:9200"
  "mahasiswa-c:PasswordC123!:9300"
  "mahasiswa-d:PasswordD123!:9400"
)

check_mc() {
  if ! command -v mc &>/dev/null; then
    echo "[ERROR] mc tidak ditemukan. Install dulu:"
    echo "  wget https://dl.min.io/client/mc/release/linux-amd64/mc"
    echo "  chmod +x mc && sudo mv mc /usr/local/bin/"
    exit 1
  fi
}

wait_ready() {
  local user=$1 pass=$2 port=$3
  echo -n "  Menunggu container port $port siap"
  for i in $(seq 1 15); do
    if curl -sf "$SERVER:$port/minio/health/live" &>/dev/null; then
      echo " OK"
      return 0
    fi
    echo -n "."
    sleep 2
  done
  echo " TIMEOUT"
  return 1
}

setup_instance() {
  local entry=$1
  local user pass port alias bucket
  user=$(echo "$entry" | cut -d: -f1)
  pass=$(echo "$entry" | cut -d: -f2)
  port=$(echo "$entry" | cut -d: -f3)
  alias="$user"
  bucket="bucket-$user"

  echo ""
  echo "==> Setup: $user (port $port)"

  wait_ready "$user" "$pass" "$port"

  mc alias set "$alias" "$SERVER:$port" "$user" "$pass" --api S3v4 >/dev/null

  # Buat bucket utama
  if ! mc ls "$alias/$bucket" &>/dev/null; then
    mc mb "$alias/$bucket"
    echo "  [OK] Bucket '$bucket' dibuat"
  else
    echo "  [SKIP] Bucket '$bucket' sudah ada"
  fi

  # Buat folder struktur awal
  echo "placeholder" | mc pipe "$alias/$bucket/tugas/.keep" 2>/dev/null || true
  echo "placeholder" | mc pipe "$alias/$bucket/temp/.keep"  2>/dev/null || true
  echo "  [OK] Struktur folder awal dibuat (tugas/ dan temp/)"

  # Set quota
  mc admin bucket quota "$alias/$bucket" --size "$QUOTA" 2>/dev/null || true
  echo "  [OK] Quota $QUOTA di-set untuk $bucket"

  echo "  [DONE] $user siap digunakan"
}

# ─── Main ────────────────────────────────────────────────────────────────────
echo "========================================"
echo " Cloud Storage Setup — MinIO per Mahasiswa"
echo "========================================"

check_mc

for entry in "${USERS[@]}"; do
  setup_instance "$entry"
done

echo ""
echo "========================================"
echo " Setup selesai!"
echo "========================================"
echo ""
echo " Akses Web Console:"
for entry in "${USERS[@]}"; do
  user=$(echo "$entry" | cut -d: -f1)
  port=$(echo "$entry" | cut -d: -f3)
  ui_port=$((port + 1))
  echo "   $user  ->  http://localhost:$ui_port"
done
echo ""
echo " Login dengan username + password dari docker-compose.yml"
