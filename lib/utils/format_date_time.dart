// Nama bulan singkat bahasa Indonesia
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

// Mengubah waktu menjadi teks, misalnya "17 Nov 2026, 14.05" (waktu lokal perangkat)
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}, '
      '${formatTime(local)}';
}

// Jam dan menit saja, misalnya "14.05" (waktu lokal perangkat)
String formatTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}
