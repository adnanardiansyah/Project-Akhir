# Arsitektur — Aplikasi Pesan Makanan (Flutter + Firebase)

Mengikuti `PRD.md` (keputusan K1 sampai K5, usulan U1 sampai U6).

## 1. Gambaran

```
Perangkat Android (satu aplikasi Flutter, dua peran)
 ├─ Firebase Authentication   → login, identitas pengguna
 ├─ Cloud Firestore           → users, restaurants, menuItems, orders, messages (realtime)
 ├─ GPS perangkat             → daftar resto dan titik tujuan checkout
 └─ OpenRouteService (HTTPS)  → jarak rute ke resto / titik tujuan pesanan
```

Tidak ada server buatan sendiri. Aplikasi bicara langsung ke Firebase dan ke OpenRouteService.
Setiap pengguna memasukkan API key miliknya sendiri saat aplikasi berjalan; key hanya disimpan di memori sesi.

## 2. Teknologi

| Bagian | Pilihan | Catatan |
|---|---|---|
| Aplikasi | Flutter (Dart) | Target Android (usulan U1) |
| Database dan login | Firebase Authentication + Cloud Firestore | K1 |
| Lokasi | paket `geolocator` | Izin lokasi diatur sesuai README paket |
| Panggilan HTTP | paket `http` | Untuk OpenRouteService |
| Konfigurasi Firebase | FlutterFire CLI (`flutterfire configure`) | |
| State | `ChangeNotifier` + `ListenableBuilder` bawaan Flutter untuk keranjang, `StreamBuilder` untuk data Firestore | Tanpa paket state tambahan |

Paket yang dipakai: `firebase_core`, `firebase_auth`, `cloud_firestore`, `geolocator`, `http`. Versi dikunci saat `flutter pub add` dan dicatat di laporan (bab Alat dan Bahan).

## 3. Struktur folder `lib/`

```
lib/
  main.dart                 // inisialisasi Firebase dan menjalankan app
  app.dart                  // MaterialApp dan routing berdasar peran
  models/                   // app_user, restaurant, menu_item, cart_item, order, chat_message
  services/                 // auth_service, restaurant_service, order_service, chat_service,
                            // location_service, route_distance_service
  controllers/              // cart_controller (ChangeNotifier)
  screens/
    auth/                   // login_screen, register_screen
    customer/               // restaurant_list_screen, menu_screen, cart_screen,
                            // payment_screen, my_orders_screen
    restaurant/             // incoming_orders_screen
    shared/                 // chat_screen, order_detail_screen (dipakai pemesan dan resto)
  theme/                    // app_theme: warna, tipografi, bentuk, durasi animasi
  widgets/                  // komponen kecil yang dipakai ulang
  utils/                    // format_rupiah, format_date_time, form_validators, format_distance
```

Font Plus Jakarta Sans (SIL OFL 1.1) dibundel di `assets/fonts/` dan didaftarkan di `pubspec.yaml`; animasi memakai fitur bawaan Flutter (tanpa paket tambahan).

Aturan: logika bisnis dan akses data di `services/` dan `models/` (bisa dites tanpa tampilan); `screens/` hanya menyusun tampilan. Nama berkas dan identifier bahasa Inggris, komentar bahasa Indonesia satu baris.

## 4. Model data Firestore

```
users/{uid}
  role: "customer" | "restaurant"
  displayName: string
  restaurantId: string?            // hanya untuk role restaurant

restaurants/{restaurantId}
  name: string
  address: string
  location: GeoPoint               // lat dan lon resto
  ownerUid: string

restaurants/{restaurantId}/menuItems/{itemId}
  name: string
  price: int                       // rupiah, bilangan bulat

orders/{orderId}
  customerUid: string
  customerName: string             // salinan nama pemesan saat dipesan
  restaurantId: string
  restaurantName: string           // salinan nama resto saat dipesan
  deliveryLocation: GeoPoint?       // salinan titik GPS tujuan saat checkout
  items: [{ menuItemId, name, price, qty }]   // salinan nama dan harga saat dipesan
  total: int
  status: "pending" | "confirmed" | "paid" | "cancelled"
  paymentMethod: string?           // diisi saat bayar (simulasi)
  createdAt: timestamp
  paidAt: timestamp?

orders/{orderId}/messages/{messageId}
  senderUid: string
  senderRole: "customer" | "restaurant"
  text: string
  createdAt: timestamp
```

Nilai jarak tidak disimpan di Firestore. Titik GPS tujuan disalin ke `orders/{orderId}.deliveryLocation` saat checkout agar tetap sama untuk pesanan tersebut. Jarak di daftar resto memakai GPS terkini; jarak di detail pesanan dihitung dari koordinat resto ke titik tujuan pesanan yang tersimpan. Jika pemesan belum mengambil lokasi, pesanan tetap bisa dibuat dan jarak detail tidak tersedia.

Kelas model pesanan di kode bernama `FoodOrder` (berkas `models/order.dart`) karena `cloud_firestore` juga mengekspor nama `Order`.

Daftar pesanan pemesan memakai `where('customerUid')` lalu diurutkan di aplikasi (terbaru di atas), sehingga tidak perlu indeks gabungan di Firestore.

Keranjang hanya untuk satu resto; menambah menu dari resto lain meminta konfirmasi untuk mengganti keranjang. Keranjang dibuat per akun dan dibuang saat keluar.

Alasan `items` menyalin nama dan harga: harga di pesanan tidak berubah kalau menu diubah belakangan.

## 5. Alur data utama

1. **Login:** `auth_service` masuk, lalu baca `users/{uid}.role`; `app.dart` membuka layar pemesan atau resto.
2. **Daftar resto dan menu (M1):** `StreamBuilder` pada `restaurants` dan `menuItems`.
3. **Keranjang dan pesanan:** `cart_controller` menyimpan item di memori; pemesan dapat mengambil GPS terbaru sebagai titik tujuan tetap. "Buat Pesanan" menulis satu dokumen `orders` dengan status `pending` dan salinan koordinat tujuan bila tersedia. Keranjang terkunci sampai server mengonfirmasi atau menolak; setelah 10 detik UI memberi tahu bahwa status masih menunggu.
4. **Chat (M2):** `chat_service` menulis ke `orders/{id}/messages`; kedua sisi mendengarkan koleksi yang sama diurutkan `createdAt`, sehingga pesan muncul tanpa refresh. Pesan lokal ditandai menunggu sampai server mengonfirmasi; bila write ditolak, teks dikembalikan ke kolom.
5. **Konfirmasi dan batal:** resto mengubah `status` ke `confirmed` atau `cancelled`; pemesan hanya boleh membatalkan sebelum `paid`.
6. **Pembayaran simulasi (M3):** pemesan memilih metode, `status` menjadi `paid`, `paymentMethod` dan `paidAt` terisi. Tidak ada uang sungguhan.
7. **Jarak rute (M4):** daftar resto menghitung dari GPS terkini pemesan ke resto. Detail pesanan menghitung dari lokasi resto ke `deliveryLocation` yang tersimpan saat checkout, sehingga tujuan tidak bergeser saat pemesan berpindah. Tombol perbarui pada daftar mengambil GPS baru. `route_distance_service` memanggil OpenRouteService; hasil meter diubah ke km oleh `format_distance`.

## 6. Integrasi OpenRouteService

Integrasi memakai host HeiGIT yang baru sesuai pengumuman resmi OpenRouteService:
- Host `api.openrouteservice.org` sudah diganti dengan `api.heigit.org`; Directions memakai `https://api.heigit.org/openrouteservice/v2/directions/{profile}`.
- Selain perubahan URL, parameter dan perilaku layanan tetap sama menurut pengumuman OpenRouteService.
- Setiap pengguna aplikasi memasukkan API key miliknya sendiri. FAQ HeiGIT melarang key pribadi pengembang ditanam untuk semua pengguna aplikasi; key pengguna hanya ditahan di memori selama sesi.

Format request dan respons Directions:
- Urutan koordinat `[lon, lat]`, bukan `[lat, lon]` (halaman FAQ).
- `GET /openrouteservice/v2/directions/{profile}` mengembalikan GeoJSON; jarak total ada di `features[].properties.summary.distance` dengan satuan meter (halaman Requests and Return Types).
- Key dikirim di header `Authorization`; koordinat asal dan tujuan dikirim sebagai `start` dan `end`.
- Batas paket gratis Standard: Directions 2.000 per hari dan 40 per menit; kena batas harian dibalas 403, batas per menit dibalas 429 (halaman paket dan FAQ resmi).

Profil yang dipakai: `driving-car` (usulan).

Key tidak disimpan di repositori, konfigurasi build, atau penyimpanan perangkat. Pengguna memasukkannya lewat tombol kunci di beranda pemesan; key hilang saat aplikasi ditutup. Untuk aplikasi produksi yang memakai satu key milik pengelola, diperlukan proxy di server, bukan key klien.

GPS terkini disimpan di memori selama sesi akun dan dihapus saat akun berganti atau keluar. Saat checkout, pemesan dapat menyalin koordinat GPS sebagai titik tujuan ke dokumen pesanan; salinan ini tidak berubah ketika GPS perangkat diperbarui. Koordinat resto tetap bersumber dari dokumen resto.

Jika GPS mati atau izinnya ditolak, label memberi petunjuk untuk mengaktifkan GPS atau izin. Jika koordinat resto belum tersedia, label menyebutkannya. Jika rute gagal karena key, kuota, jaringan, atau rute tidak ditemukan, label menyarankan memeriksa key dan koneksi. Tidak ada cadangan jarak garis lurus; fitur lain tetap dapat dipakai.

## 7. Keamanan data (aturan Firestore)

Prinsip yang ditulis di `firestore.rules`:
- Pengguna hanya membaca profilnya sendiri dan hanya boleh mengubah `displayName`; pendaftaran dari aplikasi hanya membuat peran `customer`, jadi pengguna tidak dapat memberi dirinya peran `restaurant` (U4).
- `restaurants` dan `menuItems`: semua pengguna yang login boleh membaca; tulis ditutup dari aplikasi. Data usaha nyata bersumber publik dan dimasukkan lewat Console; akun operator aplikasi tidak menyatakan hubungan dengan pemilik usaha.
- `orders`: pemesan hanya membuat dan membaca pesanan miliknya; resto hanya membaca pesanan dengan `restaurantId` yang ditetapkan di profil. Resto dapat mengonfirmasi, pemesan dapat membayar setelah dikonfirmasi, dan kedua pihak dapat membatalkan sebelum `paid`; perubahan hanya pada field status/pembayaran yang diizinkan.
- `messages`: hanya pemesan dan resto pada pesanan yang sama yang boleh membaca dan menambah pesan. `senderUid` dan `senderRole` harus cocok dengan akun login; pesan tidak dapat diubah atau dihapus.

Rules sumber ada di `firestore.rules`, ditautkan dari `firebase.json`, dan proyek default ditetapkan di `.firebaserc`. Rules lokal ini belum diuji atau dideploy dari repo, dan belum diverifikasi terhadap aturan yang mungkin sudah terpasang di Firebase Console. Langkah L8 tetap harus menguji dua akun dan alur transaksi sebelum rules diterapkan ke proyek Firebase.

## 8. Strategi tes

- **Tes unit (Dart murni):** total keranjang, format rupiah, format jarak, pengurai respons OpenRouteService (memakai contoh JSON dari dokumentasi), aturan perpindahan status pesanan.
- **Tes widget:** validasi form login dan daftar, tampilan keranjang.
- **Tes manual dua perangkat:** chat dua arah, konfirmasi, pembayaran, jarak.
- **Pemeriksaan statis:** `flutter analyze` tanpa temuan.
- **Aturan penilai:** tes dan hasilnya dinilai oleh agen yang berbeda dari yang menulis kodenya.

## 9. Pemetaan ke laporan dan video

| Bab laporan (mengikuti contoh) | Isi untuk proyek ini |
|---|---|
| 1 Pendahuluan | Latar belakang aplikasi pesan makanan, tujuan, manfaat, ruang lingkup (isi dari bagian 8 `PRD.md`) |
| 2 Dasar Teori | Flutter, Firebase Authentication, Cloud Firestore dan pembaruan realtime, geolokasi, jarak rute dan OpenRouteService |
| 3 Alat dan Bahan | Spesifikasi mesin dan versi sesungguhnya (jangan disalin dari contoh) |
| 4 Langkah-Langkah | Satu subbab per langkah `TODO.md` (L0 sampai L8) |
| 5 Hasil dan Pembahasan | Tangkapan layar tiap fitur, kendala nyata dan penyelesaiannya, analisis, keterbatasan |
| 6 Kesimpulan dan Saran | Hasil terhadap M1 sampai M5, saran (pembayaran sungguhan, key di server, iOS) |
| Daftar Pustaka | Dokumentasi resmi Flutter, Firebase, OpenRouteService |

Video: satu segmen per langkah, ditambah intro dengan nama kelompok, logo PNL, dan nama dosen (N7).
