# Cloud Storage — Praktik MinIO + Docker Compose

Materi praktik **Cloud Storage** menggunakan MinIO sebagai self-hosted object storage yang kompatibel 100% dengan AWS S3 API.

Skenario: **1 server bersama dipakai oleh 4 mahasiswa** — tiap mahasiswa mendapat container MinIO sendiri via Docker Compose.

---

## Struktur Folder

```
cloud-storage/
├── docker-compose.yml        # 4 container MinIO (A, B, C, D)
├── setup.sh                  # script inisialisasi bucket + quota
├── README.md                 # panduan ini
├── policy/
│   ├── policy-mahasiswa-a.json
│   ├── policy-mahasiswa-b.json
│   ├── policy-mahasiswa-c.json
│   └── policy-mahasiswa-d.json
└── sample-files/             # taruh file latihan di sini
```

---

## Prasyarat

Server (Linux) menjalankan Docker. Mahasiswa mengakses dari laptop masing-masing — bisa Windows, Mac, atau Linux.

### Install MinIO Client (mc) di Laptop

#### Windows (PowerShell — cara termudah)

Buka **PowerShell sebagai Administrator**, lalu jalankan:

```powershell
# Download mc.exe
Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" `
  -OutFile "$env:USERPROFILE\mc.exe"

# Pindah ke folder yang ada di PATH agar bisa dipakai dari mana saja
Move-Item "$env:USERPROFILE\mc.exe" "C:\Windows\System32\mc.exe"

# Verifikasi
mc.exe --version
```

> Kalau muncul popup "Windows protected your PC" → klik **More info** → **Run anyway**

Setelah itu semua perintah `mc` di lab ini cukup ketik `mc` (tanpa `.exe`) di PowerShell maupun CMD.

#### Windows — alternatif via Chocolatey

```powershell
# Install Chocolatey dulu jika belum ada (jalankan sebagai Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install mc via Chocolatey
choco install minio-client -y

mc --version
```

#### Mac

```bash
brew install minio/stable/mc
mc --version
```

#### Linux

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/
mc --version
```

---

## Arsitektur

```
1 Server (Host)
├── Container A  → MinIO mahasiswa-a  (API :9100 | UI :9101)
├── Container B  → MinIO mahasiswa-b  (API :9200 | UI :9201)
├── Container C  → MinIO mahasiswa-c  (API :9300 | UI :9301)
└── Container D  → MinIO mahasiswa-d  (API :9400 | UI :9401)

Tiap container:
  - Credentials sendiri (tidak bisa cross-akses)
  - Storage terpisah (./data/minio-x)
  - Quota 5 GiB per bucket
```

### Tabel Akses

| Mahasiswa | API Port | UI Port | Username     | Password      |
|-----------|----------|---------|--------------|---------------|
| A         | 9100     | 9101    | mahasiswa-a  | PasswordA123! |
| B         | 9200     | 9201    | mahasiswa-b  | PasswordB123! |
| C         | 9300     | 9301    | mahasiswa-c  | PasswordC123! |
| D         | 9400     | 9401    | mahasiswa-d  | PasswordD123! |

---

## Quick Start

### 1. Deploy semua container

```bash
docker compose up -d
```

Cek semua container berjalan:

```bash
docker compose ps
```

Output yang diharapkan:

```
NAME                  STATUS          PORTS
minio-mahasiswa-a     Up (healthy)    0.0.0.0:9100->9000/tcp, 0.0.0.0:9101->9001/tcp
minio-mahasiswa-b     Up (healthy)    0.0.0.0:9200->9000/tcp, 0.0.0.0:9201->9001/tcp
minio-mahasiswa-c     Up (healthy)    0.0.0.0:9300->9000/tcp, 0.0.0.0:9301->9001/tcp
minio-mahasiswa-d     Up (healthy)    0.0.0.0:9400->9000/tcp, 0.0.0.0:9401->9001/tcp
```

### 2. Jalankan setup otomatis

```bash
chmod +x setup.sh
./setup.sh
```

Script ini membuat:
- Bucket `bucket-mahasiswa-x` per container
- Struktur folder awal (`tugas/` dan `temp/`)
- Quota 5 GiB per bucket

### 3. Buka Web Console

Buka browser sesuai container masing-masing:

| Mahasiswa | URL                        |
|-----------|----------------------------|
| A         | http://localhost:9101      |
| B         | http://localhost:9201      |
| C         | http://localhost:9301      |
| D         | http://localhost:9401      |

Login menggunakan username dan password dari tabel di atas.

---

## LAB 1 — Setup mc Client & Koneksi

**Tujuan:** connect ke container MinIO milik sendiri dari laptop Windows via CLI.

> **Catatan:** `SERVER_IP` = IP address server tempat Docker berjalan.
> Jika server dan laptop dalam satu mesin (localhost), gunakan `127.0.0.1`.
> Jika server berbeda mesin, tanyakan IP server ke dosen/admin.

### 1.1 Buka PowerShell atau CMD

Di Windows: tekan `Win + R` → ketik `powershell` → Enter.

### 1.2 Set alias koneksi ke server

Jalankan perintah sesuai nama mahasiswa masing-masing:

```powershell
# Mahasiswa A
mc alias set myserver http://SERVER_IP:9100 mahasiswa-a PasswordA123!

# Mahasiswa B
mc alias set myserver http://SERVER_IP:9200 mahasiswa-b PasswordB123!

# Mahasiswa C
mc alias set myserver http://SERVER_IP:9300 mahasiswa-c PasswordC123!

# Mahasiswa D
mc alias set myserver http://SERVER_IP:9400 mahasiswa-d PasswordD123!
```

Contoh jika IP server adalah `192.168.1.10` dan kamu mahasiswa A:

```powershell
mc alias set myserver http://192.168.1.10:9100 mahasiswa-a PasswordA123!
```

### 1.3 Verifikasi koneksi

```powershell
mc ls myserver/
```

Output yang diharapkan:

```
[2026-05-25]  bucket-mahasiswa-a
```

Jika muncul `bucket-mahasiswa-a` berarti koneksi berhasil.

---

## LAB 2 — Upload, Download & Manage Object

**Tujuan:** kuasai operasi dasar object storage.

> **Path di Windows:** gunakan backslash `\` atau forward slash `/` — keduanya diterima PowerShell.
> Contoh: `C:\Users\NamaKamu\Downloads\laporan.pdf`

```powershell
# Buat bucket baru
mc mb myserver/my-bucket

# Upload file dari laptop (ganti path sesuai lokasi file kamu)
mc cp C:\Users\NamaKamu\Downloads\laporan.pdf myserver/my-bucket/laporan.pdf

# Upload dengan prefix (simulasi folder)
mc cp C:\Users\NamaKamu\Downloads\foto.jpg    myserver/my-bucket/tugas/minggu-1/foto.jpg
mc cp C:\Users\NamaKamu\Downloads\kode.txt    myserver/my-bucket/tugas/minggu-1/kode.txt
mc cp C:\Users\NamaKamu\Downloads\laporan.pdf myserver/my-bucket/tugas/minggu-2/laporan.pdf

# List isi bucket
mc ls myserver/my-bucket/
mc ls myserver/my-bucket/tugas/

# Lihat metadata object (size, type, tanggal)
mc stat myserver/my-bucket/laporan.pdf

# Download file ke folder Downloads
mc cp myserver/my-bucket/laporan.pdf C:\Users\NamaKamu\Downloads\hasil-download.pdf

# Hapus satu file
mc rm myserver/my-bucket/laporan.pdf

# Hapus seluruh isi bucket
mc rm --recursive --force myserver/my-bucket/
```

> **Perhatikan:** slash `/` dalam key bukan folder sungguhan — hanya prefix. Object storage menggunakan flat namespace.

**Cara cepat dapat path file di Windows:** tahan `Shift` lalu klik kanan file di Explorer → **Copy as path**. Paste langsung ke PowerShell (hapus tanda kutip di ujungnya).

---

## LAB 3 — Isolation Test (Access Control)

**Tujuan:** buktikan mahasiswa A tidak bisa mengakses container B.

```powershell
# Akses bucket SENDIRI — harus berhasil
mc ls myserver/bucket-mahasiswa-a/
```

Sekarang coba akses container teman dengan port yang berbeda:

```powershell
# Coba akses port milik mahasiswa lain (ganti SERVER_IP dan port)
mc ls http://SERVER_IP:9200/bucket-mahasiswa-b/
```

Output yang diharapkan:

```
mc: <ERROR> Unable to list folder. Access Denied.
```

Screenshot hasil error di PowerShell dan simpan sebagai bukti praktik.

**Mengapa terisolasi?**

Tiap container punya database user sendiri, credentials sendiri, dan storage volume terpisah (`./data/minio-a` vs `./data/minio-b`). Beda container = beda server MinIO yang sepenuhnya independen.

**Cara screenshot di Windows:** tekan `Win + Shift + S` → pilih area → paste ke Paint atau Word.

---

## LAB 4 — Presigned URL

**Tujuan:** bagikan file secara aman dan sementara tanpa berbagi credentials.

```powershell
# Upload file yang akan dibagikan
mc cp C:\Users\NamaKamu\Downloads\laporan.pdf myserver/bucket-mahasiswa-a/laporan.pdf

# Generate presigned URL untuk download, valid 15 menit
mc share download --expire 15m myserver/bucket-mahasiswa-a/laporan.pdf
```

Output berupa URL panjang yang bisa dibuka siapapun tanpa login:

```
URL: http://SERVER_IP:9100/bucket-mahasiswa-a/laporan.pdf
     ?X-Amz-Algorithm=AWS4-HMAC-SHA256
     &X-Amz-Credential=...
     &X-Amz-Expires=900
     &X-Amz-Signature=...
```

**Test URL di browser:** copy seluruh URL → paste ke browser → file langsung didownload tanpa login.

**Test URL via PowerShell:**

```powershell
# Paste URL lengkap dalam tanda kutip
Invoke-WebRequest -Uri "http://SERVER_IP:9100/bucket-mahasiswa-a/laporan.pdf?X-Amz-Expires=900&..." `
  -OutFile C:\Users\NamaKamu\Downloads\test-download.pdf
```

Tunggu 15 menit — coba buka URL yang sama di browser. Hasilnya:

```
403 Forbidden — Request has expired
```

**Generate URL untuk upload** (izinkan orang lain upload ke bucket kita):

```powershell
mc share upload --expire 30m myserver/bucket-mahasiswa-a/
```

---

## LAB 5 — Quota & Resource Monitoring

**Tujuan:** cegah satu mahasiswa memonopoli storage bersama.

Cek quota yang sudah di-set oleh setup.sh:

```bash
mc admin bucket quota myserver/bucket-mahasiswa-a
# Quota: 5 GiB
# Usage: ... GiB
```

Cek ukuran bucket sendiri:

```bash
mc du myserver/bucket-mahasiswa-a
mc du myserver/bucket-mahasiswa-a/tugas/
```

Simulasi upload file besar hingga mendekati quota:

```powershell
# Buat file dummy 100MB di Windows (PowerShell)
$out = New-Object byte[] (100MB)
[System.IO.File]::WriteAllBytes("C:\Users\NamaKamu\Downloads\test-100mb.bin", $out)

# Upload ke bucket
mc cp C:\Users\NamaKamu\Downloads\test-100mb.bin myserver/bucket-mahasiswa-a/test-besar.bin
```

Jika melebihi quota:

```
ERROR: Storage quota exceeded. No space left for further uploads.
```

Hapus file untuk membebaskan ruang:

```bash
mc rm myserver/bucket-mahasiswa-a/test-besar.bin
```

---

## LAB 6 — Lifecycle Policy

**Tujuan:** otomasi penghapusan file setelah periode tertentu.

```powershell
# Hapus semua file di prefix "temp/" setelah 7 hari
mc ilm rule add --expire-days 7 --prefix "temp/" myserver/bucket-mahasiswa-a

# Hapus semua file di bucket setelah 30 hari
mc ilm rule add --expire-days 30 myserver/bucket-mahasiswa-a

# Lihat rules yang aktif
mc ilm rule list myserver/bucket-mahasiswa-a
```

Output:

```
ID       Prefix  Expiry
──────── ─────── ─────────────
rule-1   temp/   expire in 7d
rule-2   *       expire in 30d
```

Hapus rule jika tidak diperlukan:

```powershell
mc ilm rule remove --id rule-1 myserver/bucket-mahasiswa-a
```

---

## LAB 7 — Backup & Restore

**Tujuan:** implementasikan 3-2-1 backup rule dan simulasikan disaster recovery.

### Backup

```powershell
# Buat folder backup di Windows
$tanggal = Get-Date -Format "yyyyMMdd"
New-Item -ItemType Directory -Path "C:\Users\NamaKamu\backup\$tanggal" -Force

# Mirror bucket ke folder lokal (simulasi backup)
mc mirror myserver/bucket-mahasiswa-a "C:\Users\NamaKamu\backup\$tanggal\bucket-mahasiswa-a"

# Verifikasi backup
Get-ChildItem "C:\Users\NamaKamu\backup\$tanggal\bucket-mahasiswa-a"
```

### Simulasi Disaster

```powershell
# Hapus SEMUA file dari bucket (simulasi kerusakan data)
mc rm --recursive --force myserver/bucket-mahasiswa-a/

# Verifikasi bucket kosong
mc ls myserver/bucket-mahasiswa-a/
# (tidak ada output — bucket kosong)
```

### Restore

```powershell
# Kembalikan dari backup lokal
$tanggal = Get-Date -Format "yyyyMMdd"
mc mirror "C:\Users\NamaKamu\backup\$tanggal\bucket-mahasiswa-a" myserver/bucket-mahasiswa-a/

# Verifikasi restore berhasil
mc ls myserver/bucket-mahasiswa-a/
mc du myserver/bucket-mahasiswa-a/
```

---

## Perintah Berguna

### Docker Compose

```bash
# Lihat status semua container
docker compose ps

# Lihat log container tertentu
docker logs minio-mahasiswa-a
docker logs -f minio-mahasiswa-a   # follow (real-time)

# Restart satu container
docker compose restart minio-a

# Stop semua tanpa hapus data
docker compose stop

# Stop dan hapus container (data di ./data/ tetap aman)
docker compose down

# Stop dan hapus container + data volume
docker compose down -v
```

### MinIO Client (mc)

```bash
# Lihat semua alias yang tersimpan
mc alias list

# Hapus alias
mc alias remove myserver

# Cek info server
mc admin info myserver

# Lihat semua bucket
mc ls myserver/

# Sinkronisasi dua bucket
mc mirror sumber/bucket tujuan/bucket

# Copy rekursif seluruh folder
mc cp --recursive ./folder/ myserver/bucket/folder/
```

---

## Troubleshooting

### Masalah di Laptop Windows (Client)

**`mc` tidak dikenali / "not recognized as a command":**

```powershell
# Pastikan mc.exe sudah ada di PATH
where.exe mc

# Jika tidak ketemu, download ulang dan letakkan di System32
Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" `
  -OutFile "C:\Windows\System32\mc.exe"
```

**Tidak bisa connect ke server (connection refused / timeout):**

```powershell
# 1. Pastikan IP server benar
ping SERVER_IP

# 2. Pastikan port bisa diakses (tidak diblokir firewall)
Test-NetConnection -ComputerName SERVER_IP -Port 9100

# 3. Coba akses Web Console via browser dulu
# http://SERVER_IP:9101
```

**`mc alias set` berhasil tapi `mc ls` error:**

```powershell
# Hapus alias lama dan set ulang
mc alias remove myserver
mc alias set myserver http://SERVER_IP:9100 mahasiswa-a PasswordA123!
mc ls myserver/
```

**Gagal upload — `path not found`:**

```powershell
# Gunakan path lengkap, bukan path relatif
# Salah:
mc cp laporan.pdf myserver/bucket-mahasiswa-a/laporan.pdf

# Benar:
mc cp C:\Users\NamaKamu\Downloads\laporan.pdf myserver/bucket-mahasiswa-a/laporan.pdf
```

**PowerShell menolak jalankan script (Execution Policy):**

```powershell
# Ubah policy untuk sesi ini saja
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Masalah di Server (Admin/Dosen)

**Container tidak bisa start:**

```bash
docker logs minio-mahasiswa-a
# Cek port sudah dipakai proses lain
ss -tlnp | grep 9100
```

**Quota tidak bisa di-set:**

```bash
# Jalankan setup.sh ulang
./setup.sh
```

---

## Perbandingan: Single Instance vs Multi Container

| Aspek               | Single MinIO (1 container)  | Multi Container (Docker Compose) |
|---------------------|-----------------------------|----------------------------------|
| Isolasi data        | Policy-based (JSON IAM)     | Full — level container           |
| Resource usage      | Hemat (1 process)           | 4x lebih boros                   |
| Kompleksitas setup  | Menengah                    | Mudah (`compose up`)             |
| Realistis ke cloud  | Ya (model AWS S3)           | Kurang                           |
| Nilai pembelajaran  | Multi-tenancy, IAM policy   | Docker, container management     |
| Jika 1 crash        | Semua user terdampak        | Hanya 1 mahasiswa terdampak      |

> **Rekomendasi:** gunakan multi container (modul ini) untuk belajar Docker Compose dan konsep container isolation. Setelah paham, diskusikan kenapa industri memilih single instance dengan IAM policy.

---

## Catatan

- Data storage tersimpan di `./data/minio-x/` — tidak terhapus saat `docker compose down`
- Untuk reset total, hapus folder `./data/` dan jalankan `setup.sh` lagi
- Credentials ada di `docker-compose.yml` — di production gunakan secrets manager atau env file terpisah
- MinIO S3 API = AWS S3 API — semua command `mc` bisa langsung dipakai dengan AWS CLI
