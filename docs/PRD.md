# PRD — Aplikasi Pesan Makanan (Projek Akhir Flutter)

Dokumen ini turunan dari modul "Projek Akhir" (1 halaman). Contoh laporan praktikum yang dikirim hanya acuan format laporan, bukan acuan isi proyek.

## 1. Identitas

- Mata kuliah: Pemrograman Aplikasi Mobile (Flutter)
- Kelompok: Adnan Ardiansyah dan Syifa Angela, kelas TRKJ 3-B (dari contoh laporan; kelompok sama sesuai konfirmasi)
- Dosen pengampu: Hari Toha Hidayat, S.Si., M.Cs. (dari contoh laporan)
- Demo: **30 November 2026**, di kampus (Politeknik Negeri Lhokseumawe)
- Nama kelompok untuk video: **belum diputuskan** (modul menyebut "nama kelompok", contoh laporan hanya mencantumkan nama anggota)
- Pembagian tugas anggota: **belum ditentukan**

## 2. Tujuan

Membuat aplikasi mobile Flutter untuk memesan makanan dari resto: pemesan melihat menu dan harga, mengobrol dengan resto untuk memastikan pesanan, membayar, dan melihat jarak rute ke resto serta titik tujuan pesanan.

## 3. Sumber kebutuhan (butir modul)

Fitur wajib dari modul:

| ID | Butir modul (ringkas) |
|---|---|
| M1 | Menu dan harga makanan |
| M2 | Chat dengan pihak resto untuk pemilihan toping, level pedas, dan ketersediaan makanan |
| M3 | Pembayaran |
| M4 | Menampilkan jarak tempuh antara tempat resto dan pemesan |
| M5 | Database memakai Firebase atau SQL |

Catatan dan penugasan dari modul:

| ID | Butir modul (ringkas) |
|---|---|
| N1 | Buat laporan lengkap proses pembuatan aplikasi |
| N2 | Buat video proses pembuatan, step by step, lengkap |
| N3 | Durasi video minimal 15 menit |
| N4 | Demo pada 30 November 2026 di kampus |
| N5 | Kumpulkan laporan dan link video yang diupload ke YouTube |
| N6 | Video yang tidak bisa dijalankan atau dibuka mengurangi nilai |
| N7 | Video memuat nama kelompok, logo PNL, dan nama dosen pengampu |

## 4. Keputusan

Sudah disetujui (17 November 2026; K4 diperbarui 20 November 2026):

| ID | Keputusan |
|---|---|
| K1 | Database: **Firebase** (Authentication + Cloud Firestore) |
| K2 | **Satu aplikasi dengan tiga peran**: pemesan (customer), resto (restaurant), dan admin |
| K3 | Pembayaran: **simulasi** (alur pembayaran tanpa uang sungguhan), kecuali dosen meminta pembayaran sungguhan |
| K4 | **Banyak resto**: struktur data mendukung banyak resto, demo memakai 2 sampai 3 restoran nyata di Lhokseumawe |
| K5 | Jarak tempuh: **jarak rute jalan** (bukan garis lurus), memakai OpenRouteService |

Usulan, **belum dikonfirmasi** (ubah di sini bila tidak cocok):

| ID | Usulan |
|---|---|
| U1 | Platform target: Android |
| U2 | Login email dan password untuk tiga peran |
| U3 | Akun operator proyek dan data restoran/menu bersumber publik diatur lewat Firebase Console; tidak ada layar resto untuk mengelola menu; akun operator bukan akun resmi pemilik usaha |
| U4 | Pemesan hanya bisa mendaftar sebagai pemesan; akun resto dan admin dibuat manual oleh pengelola |
| U5 | Status pesanan: `pending`, `confirmed`, `paid`, `cancelled` |
| U6 | Tidak ada cadangan jarak garis lurus. Daftar resto memakai GPS pemesan saat itu. Saat checkout pemesan dapat menyalin GPS terbaru sebagai titik tujuan pesanan; jika tidak tersedia, pesanan tetap dapat dibuat tetapi jarak di detail tidak ditampilkan. Perubahan GPS berikutnya tidak mengubah titik pesanan. |

## 5. Peran dan alur

**Pemesan**
1. Daftar atau masuk.
2. Melihat daftar resto beserta jarak rute (M4, M1).
3. Memilih resto, melihat menu dan harga (M1), menambah ke keranjang.
4. Opsional mengambil titik GPS tujuan di keranjang, lalu membuat pesanan berstatus `pending`; titik yang diambil disalin ke pesanan.
5. Mengobrol dengan resto pada pesanan itu: toping, level pedas, ketersediaan (M2).
6. Setelah resto mengonfirmasi (`confirmed`), memilih metode bayar simulasi dan membayar (M3), status `paid`.

**Resto**
1. Masuk dengan akun resto.
2. Melihat pesanan masuk untuk restonya saja.
3. Membalas chat pada pesanan (M2).
4. Mengonfirmasi atau membatalkan pesanan.

**Admin**
1. Masuk dengan akun admin yang dibuat manual oleh pengelola.
2. Memantau jumlah resto per status dan jumlah pesanan berjalan/dibayar.
3. Mencari dan memfilter resto, lalu menyetujui, menolak, atau menangguhkan data resto.
4. Melihat daftar pesanan dan statusnya untuk monitoring; tidak membaca chat pribadi.

Pesanan bisa dibatalkan (`cancelled`) oleh resto atau pemesan sebelum status `paid`.

## 6. Kebutuhan fungsional

| ID | Kebutuhan | Butir modul |
|---|---|---|
| FR-1 | Daftar resto dan menu: nama makanan dan harga (format rupiah) | M1 |
| FR-2 | Keranjang dan pembuatan pesanan, total dihitung dari harga menu; titik tujuan GPS dapat disalin saat checkout | M1 |
| FR-3 | Chat teks per pesanan antara pemesan dan resto, pesan muncul tanpa refresh | M2 |
| FR-4 | Pembayaran simulasi: pilih metode, lihat ringkasan total, konfirmasi, status menjadi `paid` | M3 |
| FR-5 | Jarak rute dari GPS pemesan ke resto di daftar; detail pesanan memakai titik tujuan yang disimpan saat checkout | M4 |
| FR-6 | Data (pengguna, resto, menu, pesanan, chat) tersimpan di Firebase | M5 |
| FR-7 | Login, logout, dan tampilan sesuai peran | turunan U2 |
| FR-8 | Dashboard admin: ringkasan, pencarian/filter resto, tinjauan status resto, dan pemantauan pesanan | M5 |

## 7. Kebutuhan non-fungsional

- Chat realtime: pesan baru muncul di perangkat lawan bicara tanpa refresh.
- Penulisan chat dan pesanan menunggu konfirmasi server; setelah 10 detik tanpa konfirmasi, aplikasi memberi tahu pengguna dan mencegah pesanan ganda.
- Aplikasi tidak menutup sendiri saat internet atau API jarak gagal; tampil pesan yang jelas.
- API key OpenRouteService tidak masuk ke repositori atau aplikasi bawaan; setiap pengguna memasukkan key miliknya sendiri untuk sesi berjalan.
- Akun admin tidak dapat didaftarkan dari aplikasi; perubahan status tinjauan dan akses monitoring dibatasi oleh Firestore Rules.
- Demo butuh internet (Firebase dan OpenRouteService); siapkan hotspot cadangan.
- Teks antarmuka dalam bahasa Indonesia.

## 8. Di luar cakupan

Pembayaran sungguhan (payment gateway), layar resto untuk mengelola menu, notifikasi push, rating atau ulasan, ongkos kirim, pelacakan kurir, navigasi peta, iOS.

## 9. Deliverable non-aplikasi

| ID | Deliverable | Catatan |
|---|---|---|
| N1 | Laporan | Mengikuti struktur contoh: Cover, Lembar Pengesahan, Pendahuluan, Dasar Teori, Alat dan Bahan, Langkah-Langkah, Hasil dan Pembahasan, Kesimpulan dan Saran, Daftar Pustaka |
| N2, N3 | Video proses | Direkam sambil mengerjakan, tiap langkah di `TODO.md` jadi satu segmen; total minimal 15 menit |
| N7 | Identitas di video | Nama kelompok, logo PNL, nama dosen pengampu |
| N5, N6 | YouTube | Atur visibilitas supaya bisa dibuka tanpa login (publik atau tidak publik dengan link); tes buka dari perangkat lain sebelum dikumpulkan |
| N4 | Demo | 30 November 2026, di kampus |

## 10. Kriteria selesai

- M1: daftar resto, menu, dan harga tampil dari Firestore.
- M2: dua perangkat (pemesan dan resto) saling kirim pesan pada satu pesanan, muncul tanpa refresh.
- M3: pembayaran simulasi mengubah status pesanan menjadi `paid`.
- M4: jarak rute tampil dalam km dan sesuai dengan hasil OpenRouteService untuk koordinat yang sama.
- M5: semua data ada di Firebase, bukan data tetap di kode; admin dapat meninjau resto dan memantau status pesanan.
- N1 sampai N7: laporan jadi, video minimal 15 menit memuat identitas, terunggah dan bisa dibuka dari perangkat lain.

## 11. Risiko

| Risiko | Mitigasi |
|---|---|
| Internet kampus lemah saat demo | Hotspot cadangan, uji sehari sebelumnya |
| Batas OpenRouteService gratis (Directions 2.000 per hari dan 40 per menit menurut halaman paket resmi) | Hitung jarak sekali per resto per sesi, bukan tiap layar dibuka |
| Pengguna belum memiliki key HeiGIT untuk jarak | Buat key pribadi di akun HeiGIT sebelum demo; jangan membagikan key milik anggota lain |
| Waktu sekitar 13 hari, laporan dan video ikut dikerjakan | Pekerjaan dipecah kecil, rekam dan catat tiap langkah saat dikerjakan |
| Video kurang dari 15 menit atau tidak bisa dibuka | Pantau total menit di tabel pelacak `TODO.md`, tes link di akhir |
| Lokasi GPS emulator tidak sesuai | Atur lokasi emulator manual saat uji |
| Batas waktu pengumpulan laporan dan video tidak tertulis di modul | Tanyakan ke dosen |

## 12. Pertanyaan terbuka

1. Nama kelompok untuk video (ada nama resmi atau cukup nama anggota).
2. Pembagian tugas Adnan dan Syifa.
3. Batas waktu pengumpulan laporan dan link video.
4. Apakah dosen mewajibkan pembayaran sungguhan.
5. Konfirmasi usulan U1 sampai U6.
