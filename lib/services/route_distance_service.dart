import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Alamat Directions HeiGIT untuk layanan OpenRouteService
const String _orsDirectionsUrl =
    'https://api.heigit.org/openrouteservice/v2/directions/driving-car';

// Batas tunggu satu permintaan jarak
const Duration _requestTimeout = Duration(seconds: 10);

// Mengambil jarak rute (meter) dari respons GeoJSON ORS; null bila bentuknya tidak sesuai
double? parseRouteDistanceMeters(Object? json) {
  if (json is! Map) return null;
  final features = json['features'];
  if (features is! List || features.isEmpty) return null;
  final feature = features.first;
  if (feature is! Map) return null;
  final properties = feature['properties'];
  if (properties is! Map) return null;
  final summary = properties['summary'];
  if (summary is! Map) return null;
  final distance = summary['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

// Menghitung jarak rute jalan lewat OpenRouteService; null berarti "jarak tidak tersedia"
class RouteDistanceService extends ChangeNotifier {
  String _apiKey = '';
  final http.Client _client;
  // Hasil disimpan per pasangan titik agar tiap resto cukup dihitung sekali per sesi
  final Map<String, Future<double?>> _cache = {};

  RouteDistanceService({http.Client? client})
    : _client = client ?? http.Client();

  bool get hasPersonalApiKey => _apiKey.isNotEmpty;

  // Memakai kunci pribadi pengguna hanya selama aplikasi berjalan
  void setPersonalApiKey(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == _apiKey) return;
    _apiKey = normalized;
    _cache.clear();
    notifyListeners();
  }

  // Menghapus kunci pribadi dari memori sesi
  void clearPersonalApiKey() {
    if (_apiKey.isEmpty) return;
    _apiKey = '';
    _cache.clear();
    notifyListeners();
  }

  // Jarak dari titik asal ke tujuan dalam meter
  Future<double?> distanceMeters(GeoPoint from, GeoPoint to) {
    final key = _cacheKey(from, to);
    final cached = _cache[key];
    if (cached != null) return cached;
    final result = _request(from, to);
    _cache[key] = result;
    // Kegagalan tidak disimpan agar bisa dicoba lagi, misalnya setelah internet kembali
    result.then((value) {
      if (value == null) _cache.remove(key);
    });
    return result;
  }

  // Satu permintaan ke ORS; urutan koordinat ORS adalah lon,lat
  Future<double?> _request(GeoPoint from, GeoPoint to) async {
    if (_apiKey.isEmpty) return null;
    final uri = Uri.parse(_orsDirectionsUrl).replace(
      queryParameters: {
        'start': '${from.longitude},${from.latitude}',
        'end': '${to.longitude},${to.latitude}',
      },
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Authorization': _apiKey,
              'Accept': 'application/geo+json',
            },
          )
          .timeout(_requestTimeout);
      // 403 kuota harian habis, 429 batas per menit, 404 rute tidak ditemukan
      if (response.statusCode != 200) return null;
      return parseRouteDistanceMeters(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // Titik dibulatkan sekitar 10 meter agar pergeseran GPS kecil tidak memicu permintaan baru
  static String _cacheKey(GeoPoint from, GeoPoint to) =>
      '${from.latitude.toStringAsFixed(4)},${from.longitude.toStringAsFixed(4)}'
      '->${to.latitude.toStringAsFixed(4)},${to.longitude.toStringAsFixed(4)}';
}
