# Laporan Progres Aplikasi Pesan Makanan

**Pembaruan:** 22 November 2026

**Teknologi:** Flutter, Firebase Authentication, Cloud Firestore, OpenRouteService, dan OpenStreetMap

## Ringkasan

Fitur utama aplikasi pemesan dan restoran sudah terhubung dengan Firestore. Dashboard admin untuk meninjau restoran dan memantau pesanan juga sudah dibuat. Perubahan terbaru menambahkan penugasan kurir dan pelacakan lokasi kurir secara langsung.

Fitur tracking mengirim lokasi GPS selama layar kurir tetap terbuka. Alur lengkap tracking belum dinyatakan selesai karena belum ada bukti uji langsung dari kurir hingga posisi tampil di akun pemesan. Saat ini pengujian aplikasi di Chrome juga belum berhasil tersambung ke layanan debug Flutter.

## Fitur yang sudah tersedia di kode

- Login dan pemilihan layar berdasarkan peran akun: pemesan, restoran, admin, dan kurir.
- Daftar restoran dan menu menggunakan data Firestore.
- Keranjang dan pembuatan pesanan dengan status `pending`.
- Pihak restoran dapat mengonfirmasi atau membatalkan pesanan.
- Chat pemesan dan restoran tersimpan per pesanan dan diperbarui melalui Firestore.
- Pembayaran simulasi setelah pesanan dikonfirmasi. Aplikasi belum memproses pembayaran uang sungguhan.
- Perkiraan jarak perjalanan menggunakan OpenRouteService. Titik tujuan pemesan dapat disalin ke pesanan saat checkout.
- Aturan akses Firestore tersedia di `firestore.rules` untuk membatasi akses berdasarkan peran dan pesanan.
- Dashboard admin untuk meninjau restoran, melihat ringkasan pesanan, dan menugaskan kurir.
- UI pengajuan akun restoran dan kurir dari layar masuk maupun akun pemesan.
- Admin dapat melihat, menyetujui, atau menolak pengajuan mitra. Persetujuan mengaktifkan role secara transaksional; pengajuan ditolak dapat diperbaiki dan dikirim ulang.
- Status pengajuan tampil kepada pemohon. Pengajuan restoran yang disetujui membuat profil resto berstatus `pending` untuk tinjauan katalog admin berikutnya.
- Dashboard restoran menampilkan pemberitahuan saat listing masih menunggu tinjauan, ditolak, atau ditangguhkan.
- Kurir dapat memulai pengantaran, mengirim lokasi GPS ke Firestore, dan menyelesaikan pengantaran.
- Pemesan dapat melihat posisi kurir pada peta OpenStreetMap di detail pesanan.
- Tampilan menggunakan latar terang dan palet emerald.

## Alur pesanan dan pengantaran

1. Pemesan membuat pesanan; status awal `pending`.
2. Restoran mengonfirmasi pesanan; pemesan menyelesaikan pembayaran simulasi sehingga status menjadi `paid`.
3. Admin menugaskan pesanan kepada akun berperan `courier`.
4. Kurir memulai pengantaran dan membagikan lokasi GPS.
5. Pemesan melihat lokasi terbaru kurir pada detail pesanan.
6. Kurir menyelesaikan pengantaran.

Tracking saat ini berjalan selama aplikasi kurir terbuka. Jika aplikasi ditutup, kurir perlu membuka aplikasi lagi dan melanjutkan berbagi lokasi.

## Status konfigurasi dan pengujian

- Firebase CLI tersedia: versi `15.37.0`; akun Firebase sudah login.
- Perintah `flutterfire` belum dikenali PowerShell. Instalasi/aktivasi FlutterFire CLI masih perlu diselesaikan.
- File lokal `lib/firebase_options.dart` dan `firebase.json` saat diperiksa sudah memuat konfigurasi Web dan Windows. Perubahan ini belum di-commit dan belum dibuktikan berhasil saat aplikasi berjalan.
- `web/` dan `windows/` ada sebagai folder baru yang belum di-track Git.
- Percobaan `flutter run -d chrome` gagal saat Flutter menghubungkan layanan debug Chrome melalui localhost (`SocketException`, port lokal ditolak). Ini belum membuktikan aplikasi berhasil atau gagal mengakses Firebase Web.
- Aturan Firestore tersedia di repo, tetapi belum ada bukti pada sesi ini bahwa rules lokal sudah diuji dan diterapkan ke proyek Firebase.
- UI pengajuan mitra dan aturan Firestore barunya sudah ada di working tree, tetapi belum diuji dengan akun Firebase nyata. Terapkan rules terbaru sebelum mencoba mendaftar atau meninjau pengajuan.
- `dart analyze lib` pada pemeriksaan perubahan onboarding tidak selesai dan tidak mengeluarkan hasil; karena itu, perubahan baru belum mendapat verifikasi analyzer. `git diff --check` lulus.
- Belum ada hasil uji end-to-end yang menunjukkan lokasi kurir bergerak dan tampil pada akun pemesan.
- Pada pemeriksaan sebelumnya, `dart analyze lib` menampilkan `No issues found!`, tetapi proses berakhir dengan kode 1 karena kendala penulisan berkas telemetry lokal. Pemeriksaan itu bukan pengganti uji manual tracking.

## Status Git

- Branch aktif: `master`.
- Commit lokal terbaru: `4a8c0af feat: add live courier tracking`.
- Branch lokal satu commit di depan `origin/master`; commit tracking belum ada di remote.
- Ada perubahan lokal yang belum di-commit pada `.metadata`, `firebase.json`, dan `lib/firebase_options.dart`.
- Perubahan onboarding mitra, Firestore Rules, dokumentasi, dan laporan progres ini juga masih lokal dan belum di-commit.
- Folder `web/` dan `windows/` belum di-track.
- Folder `.vscode/` juga muncul sebagai folder belum di-track; tidak diubah sebagai bagian onboarding.

Konfigurasi lokal yang belum di-commit sengaja tidak dimasukkan dalam commit laporan ini.

## Langkah berikutnya

1. Terapkan versi terbaru `firestore.rules` ke Cloud Firestore sebelum menguji pendaftaran mitra:

   ```powershell
   firebase deploy --only firestore:rules --project food-order-app-pnl
   ```

   Lalu uji akun pemohon dan admin.

2. Aktifkan FlutterFire CLI dari PowerShell:

   ```powershell
   dart pub global activate flutterfire_cli
   dart pub global run flutterfire_cli:flutterfire configure --project=food-order-app-pnl
   ```

   Pilih platform Android dan Web jika konfigurasi keduanya diperlukan. Pastikan konfigurasi Android yang sudah ada tetap tercakup.

3. Jalankan aplikasi di Android untuk menguji GPS kurir secara nyata. Gunakan `flutter devices`, lalu `flutter run -d <ID_ANDROID>`.

4. Daftarkan akun kurir dari UI, setujui sebagai admin, lalu uji penugasan dari pesanan berstatus `paid`.

5. Uji pengajuan restoran, persetujuan akun, tinjauan listing restoran, dan penolakan/pengajuan ulang.

6. Tambahkan menu restoran melalui Firestore Console; aplikasi belum memiliki layar pengelolaan menu.

7. Uji satu alur lengkap menggunakan akun dan perangkat terpisah: pesan, konfirmasi restoran, bayar simulasi, tugaskan kurir, mulai tracking, pastikan marker bergerak pada akun pemesan, lalu selesaikan pengantaran.

8. Jika target Chrome tetap diperlukan, selesaikan masalah koneksi debug Chrome dan uji Firebase Web. Opsi Flutter `web-server` dapat dipakai sebagai jalur uji lokal alternatif, dengan kemampuan debugging yang lebih terbatas.

9. Setelah seluruh perubahan konfigurasi diperiksa, putuskan apakah scaffold Windows memang dibutuhkan, lalu rapikan perubahan lokal dan perbarui status pada `docs/TODO.md`.

## Batasan yang diketahui

- Pembayaran masih simulasi; tidak ada payment gateway.
- Lokasi kurir tidak berjalan sebagai background service saat aplikasi ditutup.
- Lokasi kurir dan tampilan peta memerlukan koneksi internet serta izin lokasi pada perangkat.
- Perubahan konfigurasi Web/Windows di working tree belum dianggap terverifikasi hanya karena nilai konfigurasi sudah ada di berkas.
