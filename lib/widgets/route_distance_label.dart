import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/format_distance.dart';

// Label jarak rute dari lokasi asal ke tujuan.
class RouteDistanceLabel extends StatefulWidget {
  final AppServices services;
  // Bila ada, titik asal tetap dipakai untuk rute pesanan.
  final Future<GeoPoint?> Function()? loadOrigin;
  // Titik tujuan rute, misalnya resto di daftar atau pemesan pada detail.
  final Future<GeoPoint?> Function() loadDestination;
  // Berubah bila resto atau koordinat tujuan berubah.
  final Object destinationKey;

  const RouteDistanceLabel({
    super.key,
    required this.services,
    this.loadOrigin,
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
    if (widget.loadOrigin == null) {
      widget.services.location.addListener(_onLocationChanged);
    }
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
    final locationSourceChanged =
        (oldWidget.loadOrigin == null) != (widget.loadOrigin == null) ||
        oldWidget.services.location != widget.services.location;
    if (locationSourceChanged) {
      if (oldWidget.loadOrigin == null) {
        oldWidget.services.location.removeListener(_onLocationChanged);
      }
      if (widget.loadOrigin == null) {
        widget.services.location.addListener(_onLocationChanged);
      }
      shouldRecompute = true;
    }
    if (shouldRecompute) _distance = _compute();
  }

  @override
  void dispose() {
    widget.services.routeDistance.removeListener(_onApiKeyChanged);
    if (widget.loadOrigin == null) {
      widget.services.location.removeListener(_onLocationChanged);
    }
    super.dispose();
  }

  // Menghitung ulang jarak setelah pengguna mengatur atau menghapus key.
  void _onApiKeyChanged() {
    setState(() => _distance = _compute());
  }

  // Label daftar resto memakai GPS terbaru yang dibagikan oleh LocationService.
  void _onLocationChanged() {
    if (widget.loadOrigin == null) setState(() => _distance = _compute());
  }

  // Key pribadi dan kedua koordinat diperlukan untuk menghitung rute.
  Future<_DistanceReading> _compute() async {
    if (!widget.services.routeDistance.hasPersonalApiKey) {
      return const _DistanceReading.unavailable(
        'Masukkan key OpenRouteService',
      );
    }

    final GeoPoint origin;
    if (widget.loadOrigin != null) {
      final loadedOrigin = await _loadOrigin();
      if (loadedOrigin == null) {
        return const _DistanceReading.unavailable(
          'Koordinat asal belum tersedia',
        );
      }
      origin = loadedOrigin;
    } else {
      final result = await widget.services.location.currentLocation();
      if (result.location == null) {
        final message = switch (result.issue) {
          LocationIssue.serviceDisabled => 'Aktifkan GPS perangkat',
          LocationIssue.permissionDenied => 'Izinkan akses lokasi',
          LocationIssue.permissionDeniedForever =>
            'Izinkan lokasi lewat Pengaturan',
          LocationIssue.unavailable => 'Lokasi perangkat tidak terbaca',
          null => 'Lokasi perangkat tidak terbaca',
        };
        return _DistanceReading.unavailable(message);
      }
      origin = result.location!;
    }

    final GeoPoint? destination;
    try {
      destination = await widget.loadDestination();
    } catch (_) {
      return const _DistanceReading.unavailable(
        'Koordinat tujuan gagal dimuat',
      );
    }
    if (destination == null) {
      return const _DistanceReading.unavailable(
        'Koordinat tujuan belum tersedia',
      );
    }

    try {
      final meters = await widget.services.routeDistance.distanceMeters(
        origin,
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

  Future<GeoPoint?> _loadOrigin() async {
    try {
      return await widget.loadOrigin!();
    } catch (_) {
      return null;
    }
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
              if (widget.loadOrigin == null)
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
