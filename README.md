# food_order_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Live tracking kurir

Tracking memakai GPS ponsel kurir, Firestore real-time, dan peta OpenStreetMap.
Untuk memakai alur ini:

1. Dari layar masuk, pilih **Daftar sebagai mitra restoran atau kurir** lalu
   kirim pengajuan. Pemohon dapat memantau status dan memperbaiki pengajuan
   yang ditolak.
2. Dari folder proyek, terapkan aturan keamanan terbaru ke project yang benar:
   `firebase deploy --only firestore:rules --project food-order-app-pnl`.
3. Admin membuka tab **Pengajuan** dan menyetujui akun kurir. Role `courier`
   diaktifkan oleh transaksi admin setelah pengajuan disetujui.
4. Pemesan wajib menyimpan titik GPS saat checkout agar kurir memiliki tujuan.
5. Setelah resto mengonfirmasi dan pemesan menyelesaikan pembayaran simulasi,
   admin buka tab **Pesanan** dan pilih **Tugaskan kurir**.
6. Kurir masuk ke aplikasi, menerima izin lokasi, lalu menekan **Mulai
   pengantaran**. Pemesan melihat posisi kurir di **Pesanan saya** → detail
   pesanan.

Lokasi dikirim selama layar aplikasi kurir terbuka. Jika aplikasi ditutup,
kurir perlu membuka lagi aplikasi dan menekan **Lanjutkan berbagi lokasi**.

## Pendaftaran mitra

Pendaftaran restoran dan kurir tersedia dari layar masuk. Pemohon membuat akun
email/kata sandi dan mengirim data pengajuan; role akun tetap `customer` sampai
admin menyetujui pengajuan. Pengajuan restoran memerlukan nama usaha, alamat,
nomor telepon, dan titik lokasi GPS. Setelah admin mengaktifkan akun restoran,
listing masih berstatus `pending` sampai ditinjau di tab **Resto**. Menu restoran
baru masih perlu dimasukkan lewat Firestore Console karena aplikasi belum
menyediakan pengelolaan menu.
