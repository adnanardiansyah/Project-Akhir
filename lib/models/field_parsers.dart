// Nilai teks dari Firestore; tipe lain (mis. angka hasil edit Console) dianggap kosong
String stringOrEmpty(Object? value) => value is String ? value : '';

// Nilai teks opsional dari Firestore; tipe lain dianggap tidak ada
String? stringOrNull(Object? value) => value is String ? value : null;
