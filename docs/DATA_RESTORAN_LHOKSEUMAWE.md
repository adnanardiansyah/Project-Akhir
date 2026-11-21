# Data Restoran Lhokseumawe

Data berikut disiapkan untuk daftar restoran aplikasi. Nama, alamat, titik, dan menu mengacu pada usaha nyata di Lhokseumawe. Harga adalah harga publik pada tanggal sumber dan bisa berubah di outlet.

Pesanan dan pembayaran di aplikasi masih simulasi. Akun dengan peran `restaurant` adalah akun operator proyek; akun tersebut tidak mewakili atau menyatakan kemitraan dengan pemilik usaha.

## Dokumen `restaurants`

| ID dokumen | `name` | `address` | `location` (latitude, longitude) |
|---|---|---|---|
| `mie-bangladesh` | `Mie Bangladesh` | `Jl. Perdagangan No. 13, Pusong Baru, Banda Sakti, Kota Lhokseumawe, Aceh` | `GeoPoint(5.172317, 97.151159)` |
| `hokben-suzuya-lhokseumawe` | `HokBen - Suzuya Mall Lhokseumawe` | `Suzuya Mall, Lantai Dasar, Jl. Samudera Baru No. 1, Simpang Empat, Banda Sakti, Lhokseumawe, Aceh 24355` | `GeoPoint(5.178340088987248, 97.14837938148263)` |
| `wong-solo-lhokseumawe` | `Ayam Penyet Wong Solo Lhokseumawe` | `Jl. Darussalam, Lancang Garam, Banda Sakti, Kota Lhokseumawe, Aceh` | `GeoPoint(5.18148780, 97.14503740)` |

Setiap dokumen juga memerlukan `ownerUid`: isi dengan UID akun operator proyek yang dipasangkan ke restoran tersebut. Pada `users/{uid}`, atur `role: "restaurant"` dan `restaurantId` ke ID dokumen yang sama. Jangan memakai UID pemilik usaha tanpa persetujuan mereka.

## Subkoleksi `menuItems`

Di bawah `restaurants/{restaurantId}/menuItems/{menuItemId}`, buat dokumen dengan field `name` (string) dan `price` (integer rupiah):

| Restoran | ID menu | `name` | `price` |
|---|---|---|---:|
| Mie Bangladesh | `mie-bangladesh` | `Mie Bangladesh` | 26000 |
| HokBen | `chicken-teriyaki` | `Chicken Teriyaki` | 30000 |
| HokBen | `beef-teriyaki` | `Beef Teriyaki` | 40000 |
| Ayam Penyet Wong Solo | `naskot-ayam-penyet` | `Naskot Ayam Penyet` | 47300 |

## Sumber pengecekan

- **Mie Bangladesh:** [AJNN, 9 Maret 2025](https://www.ajnn.net/news/mie-bangladesh-kuliner-legendaris-lhokseumawe-yang-melegenda/index.html) melaporkan usaha di Jalan Perdagangan masih beroperasi dan harga seporsi Rp26.000. [Sisparnas Kementerian Pariwisata](https://sisparnas.kemenpar.go.id/p/78197) mencatat lokasinya dan menyediakan titik Google Maps.
- **HokBen:** [Info Lhokseumawe](https://infolhokseumawe.com/gaya-hidup/perdana-di-aceh-hokben-hadir-di-lhokseumawe/) mencatat gerai di lantai dasar Suzuya Mall; [daftar gerai HokBen 2025](https://www.maybank.co.id/id/Promotion/Savings/2025/06/25/08/10/-/media/Downloaded%20Content/pdf/List%20All%20Store%20HokBen%202025) mencatat alamat cabang. Harga Chicken Teriyaki dan Beef Teriyaki diambil dari [menu HokBen](https://webstaging.hokben.co.id/menu); harga outlet dapat berbeda.
- **Ayam Penyet Wong Solo:** [Restaurant Guru](https://restaurantguru.com/lhokseumawe-Lhokseumawe-2) memuat alamat, titik peta, serta aktivitas ulasan cabang. Harga Naskot Ayam Penyet Rp47.300 tercantum pada [katalog menu Wong Solo yang diperbarui 17 September 2026](https://menumakan.id/ayambakarwongsolo/); konfirmasikan harga cabang Lhokseumawe sebelum demo.

## Penerapan di Firebase Console

1. Di koleksi `restaurants`, ganti dokumen restoran fiktif dengan tiga entri di atas. Isi `ownerUid` memakai akun operator proyek masing-masing.
2. Pada `users/{uid}` setiap operator, set `role` ke `restaurant` dan `restaurantId` ke ID restoran yang sesuai.
3. Ganti subkoleksi `menuItems` dengan item yang tercantum. Hapus item menu lama yang bukan menu usaha tersebut.
4. Biarkan dokumen `orders` historis tetap ada; nama restoran dan harga pada pesanan lama tersimpan sebagai salinan.
5. Buka ulang aplikasi dan pastikan daftar menampilkan tiga nama restoran tersebut beserta menu dan jaraknya.
