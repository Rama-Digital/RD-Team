# Agent dan model Wulan

Diperiksa pada 21 September 2026.

## Jalur koneksi

| Pemakai | Alamat model | Transport |
| --- | --- | --- |
| Buzz Desktop Rama | `http://server-wulan.taila948fb.ts.net:20129/v1` | Tailscale |
| Agent RD-Team di VPS | `http://127.0.0.1:20129/v1` | SSH ke Wulan, port 42022 |

Kedua jalur model tidak melewati Cloudflare.
Koneksi chat tetap memakai `wss://team.growc.id`.
Alamat publik `https://ai.ramadigital.id/v1` tetap tersedia.

Wulan menyediakan API key terpisah untuk Desktop dan VPS.
Katalog `/v1/models` terakhir memuat 69 ID model.
Katalog dapat berubah mengikuti penyedia Wulan. Tidak semua model diuji dengan permintaan berbayar.
Ketersediaan jawaban tetap mengikuti kredensial, kuota, dan dukungan model di Wulan.

Provider Buzz memakai `openai-compat`, protokol Chat Completions, dan default `cx/gpt-5.6-terra`.
Provider ini mempertahankan ID model lengkap, termasuk awalan seperti `cx/`, `cc/`, dan `ag/`.
Timeout permintaan model adalah 1.800 detik. Idle timeout agent adalah 1.860 detik.
Batas satu giliran adalah 7.200 detik.
Konfigurasi ini bukan jaminan semua permintaan akan berjalan selama batas tersebut.
Uji yang dilakukan memakai jawaban singkat, bukan satu permintaan model selama lebih dari 120 detik.

## Desktop

Konfigurasi bersama ada di:

```text
~/.local/share/xyz.block.buzz.app/agents/global-agent-config.json
```

File ini mengandung API key dan memakai izin `600`.
Jangan salin isinya ke Git, tangkapan layar, atau pesan.
Fizz, Honey, dan Pollen mewarisi provider serta model ini jika belum memiliki override.
Fizz mulai otomatis saat Buzz dibuka. Pengaturan mulai otomatis Honey dan Pollen tetap mengikuti pengguna.
Pemilih model Buzz mengambil katalog langsung dari endpoint Wulan.
Komputer harus tersambung ke Tailnet Wulan saat menjalankan agent lokal.

## Agent bersama di VPS

Sebut `@RD-Team` di kanal `general`, atau kirim DM untuk meminta bantuan.
Agent menerima permintaan anggota yang menyebutnya pada kanal yang diikutinya.
Agent memakai dua slot tugas dan tidak menjalankan heartbeat berkala.
Komputer Rama dapat dimatikan tanpa menghentikan agent VPS.

Agent memakai identitas Nostr terpisah dan attestasi owner.
Public key agent:

```text
c053be2555327e2814ddc04d0b7a0af40f7fc1585f38789ff230c5a9d1a0d747
```

Komponen VPS:

| Komponen | Lokasi |
| --- | --- |
| Unit agent | `/etc/systemd/system/rd-team-agent.service` |
| Unit tunnel | `/etc/systemd/system/rd-team-ai-tunnel.service` |
| Konfigurasi rahasia | `/etc/rd-team-agent/agent.env` |
| Kunci SSH tunnel | `/etc/rd-team-agent/wulan-tunnel.key` |
| Host key Wulan yang dipin | `/etc/rd-team-agent/wulan-known-hosts` |
| Binary Buzz 0.5.23 | `/opt/rd-team/bin/` |
| Ruang kerja agent | `/var/lib/rd-team-agent` |

Akun lokal `rdteam-agent` dan `rdteam-tunnel` tidak memiliki login interaktif.
Unit memakai `DynamicUser=yes` dengan akun sistem yang sudah tersedia.
Akun tersedia diperlukan agar SSH dapat menyelesaikan pencarian UID pada NSS host ini.
Systemd mengelola direktori state; jalur fisiknya dapat berada di `/var/lib/private/rd-team-agent`.
Agent tidak dapat mengakses home layanan lain, konfigurasi root, atau `/opt/hermestrading.id`.
Agent dan tunnel berada dalam `user-1001.slice`, dengan batas gabungan 2 CPU dan 6 GiB.
Agent dibatasi lagi ke 1,5 GiB dan tunnel ke 128 MiB.

Pada Wulan, akun `rd-team-tunnel` hanya menerima key khusus dari IP VPS RD-Team.
SSH hanya boleh meneruskan koneksi lokal ke `127.0.0.1:20129`.
Session shell, remote forwarding, PTY, dan agent forwarding ditolak.
Konfigurasi akun berada di `/etc/ssh/sshd_config.d/95-rd-team-tunnel.conf`.
Reload konfigurasi SSH dilakukan setelah `sshd -t` lulus.

Periksa layanan:

```bash
ssh server-rama-team
sudo systemctl status rd-team-agent rd-team-ai-tunnel
sudo journalctl -u rd-team-agent -n 50 --no-pager
```

Lihat seluruh model yang saat ini tersedia:

```bash
sudo /opt/rd-team/bin/agent-models list
```

Ganti default agent VPS setelah giliran aktif selesai:

```bash
sudo /opt/rd-team/bin/agent-models use cx/gpt-5.6-terra
```

Perintah ini memvalidasi model lewat API, mencadangkan konfigurasi, lalu memulai ulang hanya agent RD-Team.
Pilih ID apa pun dari hasil `list`. ID yang tidak tersedia ditolak sebelum konfigurasi berubah.
Pemilihan model VPS saat ini melalui perintah tersebut; integrasi pengelolaan VPS dari UI Desktop belum dibuat.

## Verifikasi

- Klaim undangan dari origin Desktop berhasil mendaftarkan identitas baru.
- Owner bisa mengklaim ulang undangan lama tanpa menghabiskan kuotanya.
- Pengguna mengonfirmasi anggota tim sudah berhasil bergabung.
- Katalog model dapat diambil dengan kedua API key melalui kedua jalur privat.
- Permintaan tanpa API key tetap mendapat HTTP 401.
- Fizz mengirim `RD_TEAM_DESKTOP_OK` ke DM uji dengan Rama.
- Agent VPS mengirim `RD_TEAM_VPS_OK` ke DM uji dengan Rama.
- Environment proses membuktikan endpoint langsung dan timeout 1.800 detik digunakan.
- Pergantian model VPS diuji sampai environment proses berubah, lalu default dikembalikan.
- Akun tunnel menolak shell, tujuan port lain, dan remote forwarding.
- Namespace agent menolak akses ke HermesTrading, home relay, dan konfigurasi root.
- Baseline file unit dan commit HermesTrading diperiksa ulang.

## Cadangan dan pemulihan

Cadangan privat di komputer Rama:

```text
~/Backups/rd-team/20260921T102215Z-ai-provider/
```

Cadangan ini memuat konfigurasi Desktop sebelumnya, identitas agent, API key, dan key tunnel.
Jangan memasukkan direktori ini ke Git atau membagikannya kepada anggota tim.
State agent dicadangkan terpisah dari volume relay. Simpan salinan tambahan sebelum perubahan besar.
Snapshot konsisten dibuat saat hanya agent RD-Team berhenti sementara.
Arsip VPS ada di `/home/rdteam/backups/20260921T1044-ai-provider/agent-state-config.tar.gz`.
Salinan lokal bernama `vps-agent-state-config.tar.gz`; checksum kedua salinan cocok.
Cadangan otomatis belum dipasang.

Untuk menghentikan agent tanpa menghapus data:

```bash
sudo systemctl stop rd-team-agent
sudo systemctl stop rd-team-ai-tunnel
```

Untuk menyalakannya kembali:

```bash
sudo systemctl start rd-team-ai-tunnel
sudo systemctl start rd-team-agent
```

Untuk mengembalikan model, jalankan `agent-models use` dengan ID sebelumnya.
Konfigurasi sebelum pergantian model tersimpan di `/etc/rd-team-agent/backups/`.
Pemulihan Desktop dilakukan saat Buzz tertutup, memakai cadangan konfigurasi sebelum perubahan.
Jangan mengganti database, identitas owner, atau konfigurasi HermesTrading saat melakukan pemulihan.
