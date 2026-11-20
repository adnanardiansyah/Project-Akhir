import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format_distance.dart';

// Label jarak rute dari lokasi perangkat ke resto; gagal apa pun tampil "Jarak tidak tersedia"
class RouteDistanceLabel extends StatefulWidget {
  final AppServices services;
  // Pemuat lokasi resto; daftar resto sudah punya lokasinya, detail pesanan perlu membaca dulu
  final Future<GeoPoint?> Function() loadDestination;

  const RouteDistanceLabel({
    super.key,
    required this.services,
    required this.loadDestination,
  });

  @override
  State<RouteDistanceLabel> createState() => _RouteDistanceLabelState();
}

// Menyimpan hasil hitung agar tidak diulang tiap build
class _RouteDistanceLabelState extends State<RouteDistanceLabel> {
  late Future<double?> _distance;

  @override
  void initState() {
    super.initState();
    widget.services.routeDistance.addListener(_onApiKeyChanged);
    _distance = _compute();
  }

  @override
  void dispose() {
    widget.services.routeDistance.removeListener(_onApiKeyChanged);
    super.dispose();
  }

  // Menghitung ulang jarak setelah pengguna mengatur atau menghapus kunci
  void _onApiKeyChanged() {
    setState(() => _distance = _compute());
  }

  // Key pribadi, lokasi perangkat, dan lokasi resto diperlukan untuk meminta jarak
  Future<double?> _compute() async {
    if (!widget.services.routeDistance.hasPersonalApiKey) return null;
    final destination = await widget.loadDestination();
    if (destination == null) return null;
    final origin = await widget.services.location.currentLocation();
    if (origin == null) return null;
    return widget.services.routeDistance.distanceMeters(origin, destination);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FutureBuilder<double?>(
      future: _distance,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final meters = snapshot.data;
        final label = !done
            ? 'Menghitung jarak…'
            : !widget.services.routeDistance.hasPersonalApiKey
            ? 'Masukkan key pribadi untuk jarak'
            : meters == null
            ? 'Jarak tidak tersedia'
            : '${formatDistance(meters)} lewat jalan';
        final color = done && meters != null
            ? scheme.primary
            : scheme.onSurfaceVariant;
        return AnimatedSwitcher(
          duration: motionShort,
          child: Row(
            key: ValueKey(label),
            mainAxisSize: MainAxisSize.min,
            children: [
              done
                  ? Icon(Icons.route_rounded, size: 16, color: color)
                  : SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: color,
                      ),
                    ),
              const SizedBox(width: 6),
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color: color,
                  fontWeight: meters != null ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
