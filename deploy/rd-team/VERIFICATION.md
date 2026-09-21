# Verifikasi deployment awal

Tanggal: 21 September 2026.

## Source dan runtime

- Fork GitHub memiliki parent `block/buzz`.
- Label OCI image relay menunjuk `ef2aa1ae38fadcc0bc22b8bf6ed96b35933146be`.
- Docker melaporkan mode `rootless`, cgroup v2, dan driver cgroup systemd.
- Batas gabungan user terverifikasi: CPU 200%, MemoryHigh 5 GiB, MemoryMax 6 GiB.
- Compose valid dan keempat layanan melaporkan `healthy`.
- Docker dan cloudflared aktif serta enabled; linger user aktif.
- Listener aplikasi hanya memakai loopback.
- Tunnel Cloudflare melaporkan `healthy` dengan empat koneksi.

## Domain dan protokol

- `https://team.growc.id` menghasilkan HTTP 200 dengan TLS yang valid.
- Metadata NIP-11 menyatakan `auth_required=true` dan `restricted_writes=true`.
- Permintaan `/query` tanpa tanda tangan ditolak dengan HTTP 401.
- WebSocket NIP-42 menolak identitas di luar daftar anggota.
- WebSocket NIP-42 menerima identitas owner.
- Owner berhasil membuat kanal `general`, mengirim pesan, dan membacanya kembali.
- Pesan yang sama dapat dibaca setelah seluruh stack dihentikan dan dimulai kembali.
- Owner berhasil membuat undangan terbatas dan halaman undangannya menghasilkan HTTP 200.
- Pemeriksaan Chromium memuat halaman publik dan halaman undangan tanpa exception JavaScript.
- Browser tanpa identitas anggota menampilkan penolakan akses daftar repositori, sesuai mode relay tertutup.

## Cadangan

- Cadangan awal konsisten dibuat saat keempat layanan RD-Team berhenti.
- PostgreSQL dump dan empat volume tersimpan pada VPS.
- Salinan arsip tersimpan pada komputer Rama dengan izin privat.
- Lima checksum artefak cocok pada VPS dan salinan lokal.
- `pg_restore --list` berhasil membaca dump PostgreSQL.
- Pemulihan penuh ke instance baru belum diuji.

## HermesTrading

- Seluruh 31 checksum file unit systemd cocok dengan baseline.
- Commit tetap `bcf7f57ec034217761d46b2a56b5f42a7bd4f38b` dan working tree bersih.
- Boot ID tetap sama; VPS tidak direboot.
- Sepuluh timer tetap terdaftar.
- Tidak ada unit systemd yang failed.
- Siklus council selesai sukses selama pemasangan RD-Team.
- Pemeriksaan tidak menjalankan skrip trading atau membuat order.

## Lingkup validasi

Perubahan repository hanya menambah konfigurasi deployment, skrip operasional, dan dokumentasi.
Shell syntax, JSON, konfigurasi Compose, unit systemd, dan whitespace diperiksa.
Tidak ada perubahan kode aplikasi. Suite Rust, desktop, dan mobile tidak dijalankan.
AI agent dan push notification belum dikonfigurasi.
