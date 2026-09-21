# RD-Team

Deployment Buzz untuk tim Rama. Nama produk masih memakai Buzz.

- Situs: <https://team.growc.id>
- Alamat komunitas: `wss://team.growc.id`
- Fork: <https://github.com/Rama-Digital/RD-Team>
- Upstream: <https://github.com/block/buzz>
- Source runtime awal: `ef2aa1ae38fadcc0bc22b8bf6ed96b35933146be`.

## Masuk sebagai owner

Chat memakai aplikasi Buzz desktop/mobile. Web bawaan menyediakan halaman undangan dan penjelajah repositori Git.

1. Unduh [Buzz Desktop](https://github.com/block/buzz/releases/tag/desktop-v0.5.23).
2. Pilih impor identitas atau private key pada aplikasi.
3. Impor isi `owner.nsec` dari cadangan privat instalasi di komputer Rama.
4. Pilih **Join an existing community**.
5. Masukkan `wss://team.growc.id`.
6. Buka kanal `general`.

Jangan membagikan `owner.nsec`. Kunci ini memberikan akses owner, tanpa password terpisah.
Anggota lain membuat identitas sendiri lalu memakai undangan dari owner.
Undangan awal disimpan dalam `team-invite.json` di cadangan privat instalasi.
Undangan tersebut berlaku tujuh hari dan dapat dipakai enam kali.

Relay ini tertutup. Pemilik dan anggota yang diundang dapat masuk.
Pengguna di luar daftar anggota ditolak.
Browser tanpa identitas anggota juga ditolak saat membaca daftar repositori.
Untuk penjelajah repositori web, gunakan ekstensi NIP-07 dengan identitas anggota.
Pesan `This community is empty` pada web merujuk pada repositori Git, bukan kanal chat.

## Batas pemasangan ini

Relay, PostgreSQL, Redis, MinIO, penyimpanan Git, dan Cloudflare Tunnel berjalan di VPS.
Agent bersama `RD-Team` berjalan terus di VPS dan memakai model dari server Wulan.
Agent lokal Desktop memakai penyedia yang sama lewat Tailscale.
Lihat [konfigurasi AI dan operasi agent](AI.md) untuk model, timeout, cadangan, dan pemulihan.
Push notification mobile belum diaktifkan.
Pemasangan ini belum mencakup cadangan otomatis di lokasi lain.

## Isolasi VPS

SSH `server-rama-team` menuju VPS yang sama dengan `server-hermestrading`.
Alias lama tetap tersedia.

Relay dan penyimpanannya memakai user Linux `rdteam` dan Docker rootless.
Agent dan tunnel AI memakai akun layanan tersendiri dalam batas sumber daya RD-Team yang sama.
Data relay berada di direktori user tersebut dan volume Compose `rd-team_*`.
Layanan tidak membutuhkan perubahan firewall atau port publik tambahan.
Cloudflare Tunnel membuka koneksi keluar dan meneruskan trafik ke loopback.

| Komponen | Batas RAM | Batas CPU |
| --- | --- | --- |
| Relay | 2 GiB | 1 CPU |
| PostgreSQL | 1.5 GiB | 0.5 CPU |
| Redis | 384 MiB | 0.25 CPU |
| MinIO | 768 MiB | 0.5 CPU |
| Seluruh user RD-Team | 6 GiB, ambang tekanan 5 GiB | 2 CPU |

Batas gabungan mencakup Docker, tunnel Cloudflare, agent AI, dan tunnel SSH.
Bobot CPU dan I/O memakai nilai 50.
Port relay `127.0.0.1:18300`, readiness `127.0.0.1:18380`, dan metrik tunnel `127.0.0.1:18400` hanya tersedia lokal.

Runtime memakai Docker 29.8.1, Compose 5.5.1, dan cloudflared 2026.9.1.
Image aplikasi dan dependensi dikunci dengan digest di Compose.
Binary Docker dan cloudflared dipasang di `/home/rdteam/bin`.
Pembaruan binary dilakukan secara terencana, bukan otomatis.

## Operasi

Masuk ke VPS lalu pindah ke user layanan:

```bash
ssh server-rama-team
sudo -iu rdteam
cd /home/rdteam/app
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
```

Periksa layanan:

```bash
deploy/rd-team/compose.sh ps
deploy/rd-team/compose.sh logs --tail 100 relay
curl -fsS http://127.0.0.1:18380/_readiness
systemctl --user status docker cloudflared
deploy/rd-team/compose.sh exec -T relay buzz-admin list-members
```

Tambahkan anggota secara manual jika diperlukan:

```bash
deploy/rd-team/compose.sh exec -T relay buzz-admin add-member --pubkey NPUB_ANGGOTA --role member
```

Konfigurasi rahasia berada di `/home/rdteam/.config/rd-team/relay.env`.
Token tunnel berada di `/home/rdteam/.config/cloudflared/rd-team.token`.
Keduanya memiliki izin `600` dan tidak disimpan dalam Git.
Jangan menampilkan hasil `docker inspect` lengkap atau `compose config` lengkap karena dapat berisi rahasia.
Gunakan `compose.sh config --quiet` untuk validasi konfigurasi.

User `rdteam` memakai linger agar layanan mulai saat boot.
Container memakai kebijakan restart `unless-stopped`.

## Cadangan dan pemulihan

Jalankan cadangan saat jeda pemakaian. Perintah ini menghentikan hanya RD-Team sementara, kemudian menyalakannya kembali.

```bash
deploy/rd-team/backup.sh
```

Hasil berada di `/home/rdteam/backups/<waktu-UTC>` dengan izin privat.
Cadangan memuat dump PostgreSQL, empat volume, konfigurasi rahasia, token tunnel, dan checksum.
Simpan salinan pada perangkat terpisah. Skrip tidak menghapus cadangan lama.
Kunci identitas owner dicadangkan terpisah pada komputer Rama.

Untuk pemulihan, periksa `SHA256SUMS` dan `pg_restore --list database.dump` terlebih dahulu.
Pulihkan ke volume baru pada instance RD-Team yang terisolasi.
Gunakan versi PostgreSQL dan digest image yang tercatat dalam cadangan.
Pulihkan konfigurasi rahasia dan empat direktori volume sebelum memulai relay.
Periksa readiness, autentikasi, serta pesan sebelum mengalihkan trafik.
Jangan menimpa volume produksi atau menghapus data tanpa persetujuan Rama.

Untuk menghentikan deployment dengan data tetap tersimpan:

```bash
systemctl --user stop cloudflared
deploy/rd-team/compose.sh stop
```

Untuk menyalakannya kembali:

```bash
deploy/rd-team/compose.sh up -d --wait --wait-timeout 180
systemctl --user start cloudflared
```

Jangan menjalankan perintah terhadap layanan, timer, repository, atau data HermesTrading.

## Jika undangan menampilkan Failed to fetch

Relay harus mengizinkan origin aplikasi Desktop dalam `BUZZ_CORS_ORIGINS`.
Override deployment mencakup situs serta `tauri://localhost`, `http://tauri.localhost`, dan `https://tauri.localhost`.
Izin origin tidak menggantikan autentikasi anggota atau tanda tangan klaim undangan.
Anggota tim tidak memerlukan Tailscale atau API key untuk bergabung.

## Pengembangan fork

Checkout lokal berada di `/home/ramaaditya/Project/rd-team`.
Remote `origin` menuju fork Rama-Digital. Remote `upstream` menuju block/buzz.
Pemasangan awal memakai image resmi yang cocok dengan source upstream awal.
Perubahan source berikutnya memerlukan build image fork dan pembaruan digest deployment.

GitHub Actions fork dinonaktifkan saat bootstrap karena workflow upstream memiliki tujuan publikasi milik Block.
Variabel repository `GHCR_IMAGE` sudah diarahkan ke `ghcr.io/rama-digital/rd-team`.
Sebelum mengaktifkan Actions, sesuaikan seluruh tujuan publikasi, termasuk image push gateway, secrets, dan workflow rilis.

Export deployment di VPS memuat `REVISION` dan `DEPLOYMENT_SHA256SUMS` untuk memeriksa kesamaan dengan commit lokal.
Aktifkan Hermit sebelum operasi Git atau hook:

```bash
. ./bin/activate-hermit
```
