import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// Batas tunggu mendapatkan posisi GPS
const Duration _positionTimeout = Duration(seconds: 15);

enum LocationIssue {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationResult {
  final GeoPoint? location;
  final LocationIssue? issue;

  const LocationResult.success(this.location) : issue = null;
  const LocationResult.failure(this.issue) : location = null;
}

// Satu titik GPS kurir yang ikut dibagikan ke Firestore.
class CourierPosition {
  final GeoPoint location;
  final double? speedMetersPerSecond;
  final DateTime timestamp;

  const CourierPosition({
    required this.location,
    required this.speedMetersPerSecond,
    required this.timestamp,
  });
}

// Lokasi perangkat pemesan, dibagikan ke semua label jarak pada sesi akun.
class LocationService extends ChangeNotifier {
  // Satu permintaan lokasi dipakai bersama oleh semua label jarak.
  Future<LocationResult>? _current;
  Future<LocationResult>? _refreshing;

  Future<LocationResult> currentLocation() => _current ??= _fetch();

  // Streaming GPS kurir, tetap jalan lewat foreground service saat app ditutup.
  Future<Stream<CourierPosition>> watchPositionStream() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Aktifkan GPS perangkat kurir.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Izinkan lokasi aplikasi lewat Pengaturan.');
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Izinkan akses lokasi untuk mulai mengantar.');
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        permission == LocationPermission.whileInUse) {
      throw StateError(
        'Pilih "Izinkan sepanjang waktu" lewat tombol pengaturan lokasi.',
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: _courierSettings(),
    ).map(
      (position) => CourierPosition(
        location: GeoPoint(position.latitude, position.longitude),
        speedMetersPerSecond: position.speed.isFinite && position.speed >= 0
            ? position.speed
            : null,
        timestamp: position.timestamp,
      ),
    );
  }

  LocationSettings _courierSettings() => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 10),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Pelacakan pengantaran aktif',
        notificationText: 'Lokasi kurir dibagikan ke pemesan.',
        notificationChannelName: 'Pelacakan Kurir',
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
        enableWakeLock: true,
        enableWifiLock: true,
        setOngoing: true,
      ),
    ),
    TargetPlatform.iOS => AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      activityType: ActivityType.other,
      allowBackgroundLocationUpdates: true,
      showBackgroundLocationIndicator: true,
      pauseLocationUpdatesAutomatically: false,
    ),
    _ => const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  };

  // Android 11+ mengharuskan "Allow all the time" lewat Pengaturan.
  Future<void> openBackgroundLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {
      // Platform tanpa halaman pengaturan lokasi cukup diabaikan.
    }
  }

  // Ambil GPS terbaru; semua label jarak menghitung ulang setelah hasil tersedia.
  Future<LocationResult> refreshCurrentLocation() {
    final inProgress = _refreshing;
    if (inProgress != null) return inProgress;

    final pending = _fetch();
    _refreshing = pending;
    _current = pending;
    return _finishRefresh(pending);
  }

  Future<LocationResult> _finishRefresh(Future<LocationResult> pending) async {
    final result = await pending;
    if (identical(_current, pending)) notifyListeners();
    if (identical(_refreshing, pending)) _refreshing = null;
    return result;
  }

  // Lokasi perangkat tidak dibawa ke akun berikutnya pada perangkat yang sama.
  void clearCachedLocation() {
    if (_current == null && _refreshing == null) return;
    _current = null;
    _refreshing = null;
    notifyListeners();
  }

  // Memeriksa layanan dan izin lokasi, lalu mengambil posisi.
  Future<LocationResult> _fetch() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationIssue.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          LocationIssue.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationIssue.permissionDenied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _positionTimeout,
        ),
      );
      return LocationResult.success(
        GeoPoint(position.latitude, position.longitude),
      );
    } catch (_) {
      return const LocationResult.failure(LocationIssue.unavailable);
    }
  }
}
