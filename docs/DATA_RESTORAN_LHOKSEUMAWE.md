# Data Restoran Lhokseumawe

Data berikut disiapkan untuk daftar restoran aplikasi. Nama, alamat, titik, dan menu mengacu pada usaha nyata di Lhokseumawe. Harga adalah harga publik pada tanggal sumber dan bisa berubah di outlet.

Pesanan dan pembayaran di aplikasi masih simulasi. Akun dengan peran `restaurant` adalah akun operator proyek; akun tersebut tidak mewakili atau menyatakan kemitraan dengan pemilik usaha.

## Dokumen `restaurants`

| ID dokumen | `name` | `address` | `location` (latitude, longitude) |
|---|---|---|---|
| `resto1` | `Mie Bangladesh` | `Jl. Perdagangan No. 13, Pusong Baru, Banda Sakti, Kota Lhokseumawe, Aceh` | `GeoPoint(5.172317, 97.151159)` |
| `resto2` | `HokBen - Suzuya Mall Lhokseumawe` | `Suzuya Mall, Lantai Dasar, Jl. Samudera Baru No. 1, Simpang Empat, Banda Sakti, Lhokseumawe, Aceh 24355` | `GeoPoint(5.178340088987248, 97.14837938148263)` |
| `resto3` | `Ayam Penyet Wong Solo Lhokseumawe` | `Jl. Darussalam, Lancang Garam, Banda Sakti, Kota Lhokseumawe, Aceh` | `GeoPoint(5.18148780, 97.14503740)` |

Setiap dokumen juga memerlukan `ownerUid`: isi dengan UID akun operator proyek yang dipasangkan ke restoran tersebut. Pada `users/{uid}`, atur `role: "restaurant"` dan `restaurantId` ke ID dokumen yang sama. Jangan memakai UID pemilik usaha tanpa persetujuan mereka.

## Subkoleksi `menuItems`

Di bawah `restaurants/{restaurantId}/menuItems/{menuItemId}`, buat dokumen dengan field `name` (string) dan `price` (integer rupiah):

| Restoran | ID menu | `name` | `price` |
|---|---|---|---:|
| Mie Bangladesh | `mie-bangladesh` | `Mie Bangladesh` | 26000 |
| Mie Bangladesh | `mie-rebus-bangladesh` | `Mie Rebus Bangladesh` | 26000 |
| Mie Bangladesh | `mie-goreng-basah-daging` | `Mie Goreng Basah Daging` | 26000 |
| Mie Bangladesh | `kari-kambing` | `Kari Kambing` | 27000 |
| Mie Bangladesh | `roti-cane` | `Roti Cane` | 5000 |
| Mie Bangladesh | `martabak-telur` | `Martabak Telur` | 12000 |
| HokBen | `chicken-teriyaki` | `Chicken Teriyaki` | 31819 |
| HokBen | `beef-teriyaki` | `Beef Teriyaki` | 43637 |
| HokBen | `chicken-yakiniku` | `Chicken Yakiniku` | 31819 |
| HokBen | `beef-yakiniku` | `Beef Yakiniku` | 43637 |
| HokBen | `simple-set-chicken-teriyaki-1` | `Simple Set Chicken Teriyaki 1` | 39546 |
| HokBen | `hokkaido-miso-ramen-reguler` | `Hokkaido Miso Ramen Reguler` | 33637 |
| HokBen | `tori-ball` | `Tori Ball` | 32728 |
| HokBen | `ebi-furai` | `Ebi Furai` | 37728 |
| HokBen | `teh-kotak-sosro` | `Teh Kotak Sosro` | 9091 |
| HokBen | `fresh-orange-juice` | `Fresh Orange Juice` | 17273 |
| Ayam Penyet Wong Solo | `naskot-ayam-penyet` | `Naskot Ayam Penyet` | 47300 |
| Ayam Penyet Wong Solo | `paket-ayam-bakar` | `Paket Ayam Bakar` | 47300 |
| Ayam Penyet Wong Solo | `naskot-lombok-ijo` | `Naskot Lombok Ijo` | 47300 |
| Ayam Penyet Wong Solo | `naskot-nila-bakar` | `Naskot Nila Bakar` | 55000 |
| Ayam Penyet Wong Solo | `nasi-goreng-ayam` | `Nasi Goreng Ayam` | 46200 |
| Ayam Penyet Wong Solo | `mie-goreng-biasa` | `Mie Goreng Biasa` | 46200 |
| Ayam Penyet Wong Solo | `es-jeruk-nipis` | `Es Jeruk Nipis` | 26400 |
| Ayam Penyet Wong Solo | `es-kopi-susu` | `Es Kopi Susu` | 20900 |
| Ayam Penyet Wong Solo | `cah-brokoli` | `Cah Brokoli` | 41800 |
| Ayam Penyet Wong Solo | `tumis-kangkung` | `Tumis Kangkung` | 25300 |
| Ayam Penyet Wong Solo | `balado-cumi` | `Balado Cumi` | 53900 |
| Ayam Penyet Wong Solo | `nasi-putih` | `Nasi Putih` | 15400 |

## Sumber pengecekan

- **Mie Bangladesh:** [AJNN, 9 Maret 2025](https://www.ajnn.net/news/mie-bangladesh-kuliner-legendaris-lhokseumawe-yang-melegenda/index.html) melaporkan usaha di Jalan Perdagangan masih beroperasi dan harga seporsi Rp26.000. [detikFood, 11 Maret 2023](https://food.detik.com/foto-kuliner/d-6612082/gurih-pedas-mie-banglades-asal-lhokseumawe-jadi-incaran-turis) mencatat varian rebus/goreng Rp26.000, Mie Goreng Basah Daging Rp26.000, Kari Kambing Rp27.000, Roti Cane Rp5.000, dan Martabak Telur Rp12.000; harga dapat berubah. [Sisparnas Kementerian Pariwisata](https://sisparnas.kemenpar.go.id/p/78197) mencatat lokasinya dan menyediakan titik Google Maps.
- **HokBen:** [Info Lhokseumawe](https://infolhokseumawe.com/gaya-hidup/perdana-di-aceh-hokben-hadir-di-lhokseumawe/) mencatat gerai di lantai dasar Suzuya Mall; [daftar gerai HokBen 2025](https://www.maybank.co.id/id/Promotion/Savings/2025/06/25/08/10/-/media/Downloaded%20Content/pdf/List%20All%20Store%20HokBen%202025) mencatat alamat cabang. Nama dan harga diambil dari [menu resmi HokBen](https://www.hokben.co.id/menu) yang diperiksa 27 November 2026; harga pada menu resmi sudah termasuk pajak, sedangkan harga di outlet dapat berbeda.
- **Ayam Penyet Wong Solo:** [Restaurant Guru](https://restaurantguru.com/lhokseumawe-Lhokseumawe-2) memuat alamat, titik peta, serta aktivitas ulasan cabang. Nama dan harga mengacu pada [katalog menu Wong Solo yang diperbarui 17 September 2026](https://menumakan.id/ayambakarwongsolo/); [data kontak cabang Lhokseumawe](https://idfirms.com/aceh/ayam-penyet-wong-solo-lhokseumawe-77802) dan [menu referensi Seutui 2026](https://menukuliner.net/menu/43191/ayam-bakar-ayam-penyet-wong-solo-seutui) dipakai sebagai pembanding, bukan pengganti konfirmasi harga outlet.

## Penerapan di Firebase Console

1. Di koleksi `restaurants`, pakai tiga dokumen yang sudah ada: `resto1`, `resto2`, dan `resto3`. Jangan buat dokumen baru; isi `ownerUid` memakai akun operator proyek masing-masing.
2. Pada `users/{uid}` setiap operator, set `role` ke `restaurant` dan `restaurantId` ke ID restoran yang sesuai.
3. Ganti subkoleksi `menuItems` dengan item yang tercantum. Hapus item menu lama yang bukan menu usaha tersebut.
4. Biarkan dokumen `orders` historis tetap ada; nama restoran dan harga pada pesanan lama tersimpan sebagai salinan.
5. Buka ulang aplikasi dan pastikan daftar menampilkan tiga nama restoran tersebut beserta menu dan jaraknya.
