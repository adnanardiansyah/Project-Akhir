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

1. Buat akun kurir di Firebase Authentication dengan metode Email/Password.
2. Buat `users/{UID}` di Firestore dengan field string `role: courier` dan
   `displayName` berisi nama kurir.
3. Terapkan aturan keamanan dari `firestore.rules` ke Cloud Firestore.
4. Pemesan wajib menyimpan titik GPS saat checkout agar kurir memiliki tujuan.
5. Setelah resto mengonfirmasi dan pemesan menyelesaikan pembayaran simulasi,
   admin buka tab **Pesanan** dan pilih **Tugaskan kurir**.
6. Kurir masuk ke aplikasi, menerima izin lokasi, lalu menekan **Mulai
   pengantaran**. Pemesan melihat posisi kurir di **Pesanan saya** → detail
   pesanan.

Lokasi dikirim selama layar aplikasi kurir terbuka. Jika aplikasi ditutup,
kurir perlu membuka lagi aplikasi dan menekan **Lanjutkan berbagi lokasi**.
