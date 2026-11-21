import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/format_distance.dart';

// Label jarak rute dari GPS perangkat ke resto.
class RouteDistanceLabel extends StatefulWidget {
  final AppServices services;
  // Pemuat lokasi resto; detail pesanan perlu membaca resto dari Firestore.
  final Future<GeoPoint?> Function() loadDestination;
  // Berubah bila resto atau koordinat tujuan berubah.
  final Object destinationKey;

  const RouteDistanceLabel({
    super.key,
    required this.services,
    required this.loadDestination,
    required this.destinationKey,
  });

  @override
  State<RouteDistanceLabel> createState() => _RouteDistanceLabelState();
}

class _RouteDistanceLabelState extends State<RouteDistanceLabel> {
  late Future<_DistanceReading> _distance;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    widget.services.routeDistance.addListener(_onApiKeyChanged);
    widget.services.location.addListener(_onLocationChanged);
    _distance = _compute();
  }

  @override
  void didUpdateWidget(covariant RouteDistanceLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldRecompute = oldWidget.destinationKey != widget.destinationKey;
    if (oldWidget.services.routeDistance != widget.services.routeDistance) {
      oldWidget.services.routeDistance.removeListener(_onApiKeyChanged);
      widget.services.routeDistance.addListener(_onApiKeyChanged);
      shouldRecompute = true;
    }
    if (oldWidget.services.location != widget.services.location) {
      oldWidget.services.location.removeListener(_onLocationChanged);
      widget.services.location.addListener(_onLocationChanged);
      shouldRecompute = true;
    }
    if (shouldRecompute) _distance = _compute();
  }

  @override
  void dispose() {
    widget.services.routeDistance.removeListener(_onApiKeyChanged);
    widget.services.location.removeListener(_onLocationChanged);
    super.dispose();
  }

  // Menghitung ulang jarak setelah pengguna mengatur atau menghapus key.
  void _onApiKeyChanged() {
    setState(() => _distance = _compute());
  }

  // Semua label memakai GPS terbaru yang dibagikan oleh LocationService.
  void _onLocationChanged() {
    setState(() => _distance = _compute());
  }

  // Key pribadi, GPS perangkat, dan koordinat resto diperlukan untuk rute.
  Future<_DistanceReading> _compute() async {
    if (!widget.services.routeDistance.hasPersonalApiKey) {
      return const _DistanceReading.unavailable(
        'Masukkan key OpenRouteService',
      );
    }

    final GeoPoint? destination;
    try {
      destination = await widget.loadDestination();
    } catch (_) {
      return const _DistanceReading.unavailable('Lokasi resto gagal dimuat');
    }
    if (destination == null) {
      return const _DistanceReading.unavailable(
        'Koordinat resto belum tersedia',
      );
    }

    final origin = await widget.services.location.currentLocation();
    if (origin.location == null) {
      final message = switch (origin.issue) {
        LocationIssue.serviceDisabled => 'Aktifkan GPS perangkat',
        LocationIssue.permissionDenied => 'Izinkan akses lokasi',
        LocationIssue.permissionDeniedForever =>
          'Izinkan lokasi lewat Pengaturan',
        LocationIssue.unavailable => 'Lokasi perangkat tidak terbaca',
        null => 'Lokasi perangkat tidak terbaca',
      };
      return _DistanceReading.unavailable(message);
    }

    try {
      final meters = await widget.services.routeDistance.distanceMeters(
        origin.location!,
        destination,
      );
      if (meters != null) return _DistanceReading.success(meters);
    } catch (_) {
      // Endpoint, kuota, key, dan kegagalan jaringan dijelaskan di label.
    }
    return const _DistanceReading.unavailable(
      'Rute gagal dihitung; periksa key dan koneksi',
    );
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshing || !widget.services.routeDistance.hasPersonalApiKey) {
      return;
    }
    setState(() => _isRefreshing = true);
    try {
      await widget.services.location.refreshCurrentLocation();
      await _distance;
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FutureBuilder<_DistanceReading>(
      future: _distance,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final reading = snapshot.data;
        final meters = reading?.meters;
        final label = !done
            ? 'Menghitung jarak…'
            : snapshot.hasError
            ? 'Jarak gagal dihitung'
            : meters == null
            ? reading?.message ?? 'Jarak tidak tersedia'
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
              Flexible(
                child: Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: color,
                    fontWeight: meters != null ? FontWeight.w700 : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui lokasi dan jarak',
                onPressed:
                    done &&
                        widget.services.routeDistance.hasPersonalApiKey &&
                        !_isRefreshing
                    ? _refreshLocation
                    : null,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon: _isRefreshing
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DistanceReading {
  final double? meters;
  final String? message;

  const _DistanceReading.success(this.meters) : message = null;
  const _DistanceReading.unavailable(this.message) : meters = null;
}
