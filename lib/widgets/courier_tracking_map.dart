import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/route_distance_service.dart';
import '../utils/format_distance.dart';

// Posisi kurir yang dibagikan realtime, titik tujuan, dan rute/ETA opsional.
class CourierTrackingMap extends StatefulWidget {
  final GeoPoint? courierLocation;
  final GeoPoint? destination;
  final RouteDistanceService? routeService;

  const CourierTrackingMap({
    super.key,
    required this.courierLocation,
    required this.destination,
    this.routeService,
  });

  @override
  State<CourierTrackingMap> createState() => _CourierTrackingMapState();
}

class _CourierTrackingMapState extends State<CourierTrackingMap> {
  final MapController _controller = MapController();
  bool _mapReady = false;
  RouteInfo? _route;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    widget.routeService?.addListener(_handleRouteServiceChanged);
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant CourierTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeService != widget.routeService) {
      oldWidget.routeService?.removeListener(_handleRouteServiceChanged);
      widget.routeService?.addListener(_handleRouteServiceChanged);
    }
    if (oldWidget.courierLocation != widget.courierLocation ||
        oldWidget.destination != widget.destination ||
        oldWidget.routeService != widget.routeService) {
      _loadRoute();
    }

    final location = widget.courierLocation;
    final oldLocation = oldWidget.courierLocation;
    if (location == null ||
        (oldLocation?.latitude == location.latitude &&
            oldLocation?.longitude == location.longitude)) {
      return;
    }
    final target = widget.destination;
    final fitPoints = <LatLng>[
      LatLng(location.latitude, location.longitude),
      if (target != null) LatLng(target.latitude, target.longitude),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: fitPoints,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
    });
  }

  @override
  void dispose() {
    widget.routeService?.removeListener(_handleRouteServiceChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleRouteServiceChanged() => _loadRoute();

  Future<void> _loadRoute() async {
    final requestId = ++_routeRequestId;
    final service = widget.routeService;
    final courier = widget.courierLocation;
    final target = widget.destination;
    if (service == null ||
        !service.hasPersonalApiKey ||
        courier == null ||
        target == null) {
      if (mounted) setState(() => _route = null);
      return;
    }
    final info = await service.routeInfo(courier, target);
    if (!mounted || requestId != _routeRequestId || identical(_route, info)) {
      return;
    }
    setState(() => _route = info);
  }

  String _formatEta(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = seconds < 60 ? 1 : (seconds / 60).round().clamp(1, 999);
    return '$minutes mnt';
  }

  @override
  Widget build(BuildContext context) {
    final courier = widget.courierLocation;
    final target = widget.destination;
    if (courier == null && target == null) {
      return const SizedBox.shrink();
    }

    final courierPoint = courier == null
        ? null
        : LatLng(courier.latitude, courier.longitude);
    final destinationPoint = target == null
        ? null
        : LatLng(target.latitude, target.longitude);
    final points = [?courierPoint, ?destinationPoint];
    final pointsDiffer =
        courier != null &&
        target != null &&
        (courier.latitude != target.latitude ||
            courier.longitude != target.longitude);
    final singlePoint = courierPoint ?? destinationPoint!;
    final initialCenter =
        pointsDiffer && courierPoint != null && destinationPoint != null
        ? LatLng(
            (courierPoint.latitude + destinationPoint.latitude) / 2,
            (courierPoint.longitude + destinationPoint.longitude) / 2,
          )
        : singlePoint;
    final route = _route;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 290,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: pointsDiffer ? 14 : 15,
                initialCameraFit: pointsDiffer
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(48),
                        maxZoom: 16,
                      )
                    : null,
                minZoom: 5,
                maxZoom: 19,
                onMapReady: () => _mapReady = true,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.ac.pnl.food_order_app',
                ),
                if (route != null && route.polyline.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.polyline,
                        color: const Color(0xFF2563EB),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (courierPoint case final courierMarkerPoint?)
                      Marker(
                        point: courierMarkerPoint,
                        width: 54,
                        height: 54,
                        child: const _MapPin(
                          icon: Icons.delivery_dining_rounded,
                          color: Color(0xFF059669),
                        ),
                      ),
                    if (destinationPoint case final destinationMarkerPoint?)
                      Marker(
                        point: destinationMarkerPoint,
                        width: 50,
                        height: 50,
                        child: const _MapPin(
                          icon: Icons.location_on_rounded,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (courierPoint != null) ...[
                            const _LegendDot(color: Color(0xFF059669)),
                            const SizedBox(width: 6),
                            const Text(
                              'Kurir',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF17211D),
                              ),
                            ),
                          ],
                          if (courierPoint != null && destinationPoint != null)
                            const SizedBox(width: 12),
                          if (destinationPoint != null) ...[
                            const _LegendDot(color: Color(0xFFE11D48)),
                            const SizedBox(width: 6),
                            const Text(
                              'Tujuan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF17211D),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (route != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${formatDistance(route.distanceMeters)} · ETA '
                          '${_formatEta(route.duration)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ] else if (widget.routeService != null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Rute/ETA: masukkan API key ORS',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapPin({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
