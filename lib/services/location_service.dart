import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

// Batas tunggu mendapatkan posisi GPS
const Duration _positionTimeout = Duration(seconds: 15);

// Lokasi perangkat pemesan; null bila layanan lokasi mati, izin ditolak, atau gagal
class LocationService {
  // Posisi diminta sekali per sesi agar izin dan GPS tidak dipanggil berulang
  Future<GeoPoint?>? _current;

  // Lokasi saat ini; kegagalan tidak disimpan agar bisa dicoba lagi
  Future<GeoPoint?> currentLocation() {
    final pending = _current ??= _fetch();
    pending.then((value) {
      if (value == null) _current = null;
    });
    return pending;
  }

  // Memeriksa layanan dan izin lokasi, lalu mengambil posisi
  Future<GeoPoint?> _fetch() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _positionTimeout,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
