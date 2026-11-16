# Arsitektur — Aplikasi Pesan Makanan (Flutter + Firebase)

Mengikuti `PRD.md` (keputusan K1 sampai K5, usulan U1 sampai U6).

## 1. Gambaran

```
Perangkat Android (satu aplikasi Flutter, dua peran)
 ├─ Firebase Authentication   → login, identitas pengguna
 ├─ Cloud Firestore           → users, restaurants, menuItems, orders, messages (realtime)
 ├─ GPS perangkat             → lokasi pemesan
 └─ OpenRouteService (HTTPS)  → jarak rute pemesan → resto
```

Tidak ada server buatan sendiri. Aplikasi bicara langsung ke Firebase dan ke OpenRouteService.

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
                            // order_detail_screen, payment_screen, my_orders_screen
    restaurant/             // incoming_orders_screen
    shared/                 // chat_screen
  theme/                    // app_theme: warna, tipografi, bentuk, durasi animasi
  widgets/                  // komponen kecil yang dipakai ulang
  utils/                    // format_rupiah, format_distance
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

Jarak tidak disimpan di Firestore; dihitung di aplikasi dari lokasi perangkat dan `location` resto.

Kelas model pesanan di kode bernama `FoodOrder` (berkas `models/order.dart`) karena `cloud_firestore` juga mengekspor nama `Order`.

Daftar pesanan pemesan memakai `where('customerUid')` lalu diurutkan di aplikasi (terbaru di atas), sehingga tidak perlu indeks gabungan di Firestore.

Keranjang hanya untuk satu resto; menambah menu dari resto lain meminta konfirmasi untuk mengganti keranjang. Keranjang dibuat per akun dan dibuang saat keluar.

Alasan `items` menyalin nama dan harga: harga di pesanan tidak berubah kalau menu diubah belakangan.

## 5. Alur data utama

1. **Login:** `auth_service` masuk, lalu baca `users/{uid}.role`; `app.dart` membuka layar pemesan atau resto.
2. **Daftar resto dan menu (M1):** `StreamBuilder` pada `restaurants` dan `menuItems`.
3. **Keranjang dan pesanan:** `cart_controller` menyimpan item di memori; "Buat Pesanan" menulis satu dokumen `orders` dengan status `pending`.
4. **Chat (M2):** `chat_service` menulis ke `orders/{id}/messages`; kedua sisi mendengarkan koleksi yang sama diurutkan `createdAt`, sehingga pesan muncul tanpa refresh.
5. **Konfirmasi dan batal:** resto mengubah `status` ke `confirmed` atau `cancelled`; pemesan hanya boleh membatalkan sebelum `paid`.
6. **Pembayaran simulasi (M3):** pemesan memilih metode, `status` menjadi `paid`, `paymentMethod` dan `paidAt` terisi. Tidak ada uang sungguhan.
7. **Jarak rute (M4):** `location_service` mengambil lokasi perangkat, `route_distance_service` memanggil OpenRouteService, hasil meter diubah ke km oleh `format_distance`.

## 6. Integrasi OpenRouteService

Sudah terbukti dari dokumentasi resmi OpenRouteService (`giscience.github.io/openrouteservice`):
- Urutan koordinat `[lon, lat]`, bukan `[lat, lon]` (halaman FAQ).
- `GET /v2/directions/{profile}` mengembalikan GeoJSON; jarak total ada di `features[].properties.summary.distance` dengan satuan meter (halaman Requests and Return Types).
- `POST /v2/directions/{profile}` mengembalikan JSON; jarak total di `routes[].summary.distance`, meter.
- Batas paket gratis Standard: Directions 2.000 per hari dan 40 per menit; kena batas harian dibalas 403, batas per menit dibalas 429 (halaman paket dan FAQ resmi).

Profil yang dipakai: `driving-car` (usulan).

**Belum terbukti, harus dicek saat langkah L7 sebelum dikodekan:**
- Cara mengirim API key (header atau parameter). Spesifikasi pihak ketiga menyebut header `Authorization`, dokumentasi resmi yang saya baca belum menyatakannya.
- Alamat dasar API publik (`api.openrouteservice.org` muncul di contoh forum resmi ORS, belum dari dokumentasi referensi).
Kedua hal ini diperiksa di API Playground resmi dan dicoba dengan satu permintaan nyata.

Penanganan key: dikirim lewat `--dart-define=ORS_API_KEY=...` dan dibaca dengan `String.fromEnvironment`; tidak ditulis di kode dan tidak di-commit. Key yang tertanam di aplikasi tetap bisa diambil orang yang membongkar aplikasi; untuk tugas kuliah ini diterima dan dicatat di bagian saran laporan.

Kegagalan (tanpa internet, izin lokasi ditolak, 403, 429, rute tidak ditemukan): tampil "jarak tidak tersedia" (usulan U6), aplikasi tetap jalan.

## 7. Keamanan data (aturan Firestore)

Prinsip yang ditulis di `firestore.rules`:
- Pengguna hanya membaca dan mengubah dokumen `users` miliknya; **tidak boleh mengubah `role` menjadi `restaurant`** (U4).
- `restaurants` dan `menuItems`: semua pengguna yang login boleh membaca; tulis ditutup dari aplikasi (data contoh diisi lewat Console).
- `orders`: pemesan membaca dan membuat pesanan miliknya; resto hanya membaca dan mengubah pesanan dengan `restaurantId` miliknya.
- `messages`: hanya pemesan dan resto pada pesanan itu yang boleh membaca dan menulis; `senderUid` harus sama dengan pengguna yang login.

Teks aturan ditulis dan diuji di langkah L8 dengan dua akun berbeda.

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
