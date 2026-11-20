// Mengubah jarak meter menjadi teks: di bawah 1 km dalam meter, selebihnya km satu desimal ("2,3 km")
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');
  return '$km km';
}
