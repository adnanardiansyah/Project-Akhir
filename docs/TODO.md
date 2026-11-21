# TODO — Aplikasi Pesan Makanan

Mengikuti `PRD.md` dan `ARSITEKTUR.md`. Jadwal di bawah adalah **usulan** (hari ini 17 November 2026, demo 30 November 2026). Pembagian tugas Adnan dan Syifa: **belum ditentukan**.

## Aturan kerja

- Sebelum mulai koding, cek pekerjaan sesuai `PRD.md`, `ARSITEKTUR.md`, dan `TODO.md`.
- Sebelum menambah logika, endpoint, atau berkas, cek kode yang ada supaya tidak duplikat. Tidak ada dead code.
- Identifier (variabel, fungsi, kelas, berkas) bahasa Inggris. Komentar bahasa Indonesia, satu baris pendek yang menjelaskan fungsi kode.
- Mulai L4 (keputusan 17 Nov 2026): agen membuat commit sendiri satu kali di akhir tiap langkah, setelah tes dan peninjauan, dengan pesan pendek bahasa Inggris berawalan tipe, tanpa atribusi agen. Agen tidak push dan tidak menjalankan git lain yang mengubah riwayat. Sebelum commit, pastikan `env.json` tidak ikut.
- Tes dinilai oleh agen yang berbeda dari penulis kode.
- Klaim harus terbukti: baca kode, keluaran perintah, atau dokumentasi resmi. Kalau belum terbukti, dicek dulu, lalu tanya.
- **Rekam layar sambil mengerjakan** setiap langkah (untuk video N2, N3), dan catat error nyata yang muncul (untuk bab 5.2 laporan).

## Pelacak (isi saat mengerjakan)

| Langkah | Selesai | Rekaman (menit) | Subbab laporan | Pelaksana |
|---|---|---|---|---|
| L0 | | | | |
| L1 | | | | |
| L2 | | | | |
| L3 | | | | |
| L4 | | | | |
| L5 | | | | |
| L6 | | | | |
| L7 | | | | |
| L8 | | | | |
| **Total rekaman** | | **minimal 15** | | |

## Langkah

### L0 — Persiapan (17–18 Nov)
- Pekerjaan: cek alat (`flutter doctor`), buat proyek Flutter, buat proyek Firebase, hubungkan lewat FlutterFire CLI, daftar API key OpenRouteService, buat struktur folder `lib/` sesuai arsitektur, catat versi alat untuk laporan.
- Tes: aplikasi kosong jalan di emulator atau HP; satu pembacaan Firestore berhasil.
- Commit: `chore: init flutter project and firebase config`

### L1 — Login dan peran (19 Nov) — FR-7
- Pekerjaan: daftar pemesan, login, logout, pengalihan layar sesuai `role`; akun operator restoran proyek dibuat lewat Console.
- Tes: daftar lalu login lalu logout; akun resto masuk ke layar resto; tes unit validasi form.
- Commit: `feat: add auth with customer and restaurant roles`

### L2 — Resto dan menu (20 Nov) — M1, FR-1
- Pekerjaan: isi 2–3 restoran nyata di Lhokseumawe beserta menu dan harga bersumber publik di Firestore; gunakan `docs/DATA_RESTORAN_LHOKSEUMAWE.md`; layar daftar resto dan layar menu dengan harga format rupiah.
- Tes: data tampil dari Firestore; ubah satu harga di Console, tampilan ikut berubah; tes unit format rupiah.
- Commit: `feat: add restaurant list and menu with prices`

### L3 — Keranjang dan pesanan (21 Nov) — FR-2
- Pekerjaan: `cart_controller`, layar keranjang, "Buat Pesanan" menulis `orders` status `pending`.
- Tes: tes unit total keranjang; dokumen pesanan muncul di Console dengan `items` dan `total` benar.
- Commit: `feat: add cart and order creation`

### L4 — Chat realtime (22 Nov) — M2, FR-3
- Pekerjaan: `chat_service`, layar chat per pesanan, pesan urut `createdAt`.
- Tes: dua perangkat (pemesan dan resto), pesan muncul di sisi lawan tanpa refresh; pesan kosong ditolak.
- Commit: `feat: add realtime order chat`

### L5 — Sisi resto (23 Nov) — FR-3, FR-7
- Pekerjaan: layar pesanan masuk untuk resto, tombol konfirmasi dan batal, status tampil di sisi pemesan.
- Tes: resto hanya melihat pesanan restonya; konfirmasi mengubah status di layar pemesan; tes unit aturan perpindahan status.
- Commit: `feat: add restaurant order handling`

### L6 — Pembayaran simulasi (24 Nov) — M3, FR-4
- Pekerjaan: layar pembayaran (pilih metode, ringkasan total, konfirmasi), status menjadi `paid`.
- Tes: pembayaran hanya bisa dari status `confirmed`; setelah bayar status `paid` dan tidak bisa dibatalkan.
- Commit: `feat: add simulated payment`

### L7 — Jarak rute (25 Nov) — M4, FR-5
- Pekerjaan: gunakan host HeiGIT resmi dan pola key pribadi per pengguna seperti di `ARSITEKTUR.md` bagian 6; implementasikan `location_service`, `route_distance_service`, tampilan di daftar resto dan detail pesanan, serta penanganan error.
- Tes: tes unit pengurai respons dan endpoint HeiGIT; manual: pengguna memasukkan key miliknya di aplikasi, atur lokasi emulator, bandingkan jarak dengan hasil OpenRouteService untuk koordinat yang sama, pastikan detail tetap memakai titik yang disalin saat checkout setelah GPS berubah, uji izin lokasi ditolak dan tanpa internet.
- Commit: `feat: add route distance via openrouteservice`

### L8 — Keamanan dan kondisi error (26 Nov) — M5
- Pekerjaan: rules sumber ada di `firestore.rules` dan `firebase.json`; uji di emulator/Rules Playground sebelum deploy; siapkan profil admin manual dan tinjau resto lama yang berstatus `pending`.
- Tes: akun A tidak bisa membaca pesanan/chat akun B; admin tidak bisa membaca chat; pengguna tidak bisa mengubah `role` sendiri; resto tidak bisa membaca pesanan resto lain; hanya admin dapat mengubah status tinjauan resto; hanya pihak terkait dapat mengonfirmasi, membatalkan, atau membayar.
- Commit: `feat: add firestore security rules`

### L9 — Pengujian menyeluruh (27–28 Nov)
- Pekerjaan: jalankan alur lengkap pemesan–resto di dua perangkat sesuai bagian 10 `PRD.md`; `flutter analyze`; semua tes; perbaiki bug.
- Tes: tanpa temuan `flutter analyze`, semua tes lulus, penilaian oleh agen berbeda dari penulis kode.
- Commit: `test: add end-to-end fixes and final test pass`

### L10 — Laporan dan video (28–29 Nov) — N1, N2, N3, N5, N6, N7
- Pekerjaan: selesaikan laporan sesuai pemetaan di `ARSITEKTUR.md` bagian 9; susun video dari rekaman per langkah; tambah intro nama kelompok, logo PNL, nama dosen; cek total minimal 15 menit; unggah ke YouTube.
- Tes: link YouTube dibuka dari perangkat atau browser lain tanpa login dan bisa diputar sampai selesai; durasi minimal 15 menit.
- Commit: `docs: add final report`

### L11 — Gladi demo (29 Nov) — N4
- Pekerjaan: pasang aplikasi di perangkat demo, uji di jaringan yang berbeda dari rumah, siapkan hotspot, siapkan dua perangkat (pemesan dan operator restoran proyek), siapkan akun pengujian.
- Tes: satu alur penuh dari login sampai `paid` plus jarak rute, tanpa bantuan laptop.
- Commit: tidak ada (kecuali ada perbaikan: `fix: ...`)

## Pertanyaan terbuka (lihat `PRD.md` bagian 12)

1. Nama kelompok untuk video.
2. Pembagian tugas.
3. Batas waktu pengumpulan laporan dan link video.
4. Pembayaran sungguhan atau simulasi menurut dosen.
5. Konfirmasi usulan U1 sampai U6.
