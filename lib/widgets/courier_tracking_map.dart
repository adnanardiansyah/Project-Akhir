import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Posisi kurir yang dibagikan realtime dan titik tujuan pemesan.
class CourierTrackingMap extends StatefulWidget {
  final GeoPoint? courierLocation;
  final GeoPoint? destination;

  const CourierTrackingMap({
    super.key,
    required this.courierLocation,
    required this.destination,
  });

  @override
  State<CourierTrackingMap> createState() => _CourierTrackingMapState();
}

class _CourierTrackingMapState extends State<CourierTrackingMap> {
  final MapController _controller = MapController();
  bool _mapReady = false;

  @override
  void didUpdateWidget(covariant CourierTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.courierLocation;
    final oldLocation = oldWidget.courierLocation;
    if (location == null ||
        (oldLocation?.latitude == location.latitude &&
            oldLocation?.longitude == location.longitude)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _controller.move(
        LatLng(location.latitude, location.longitude),
        _controller.camera.zoom,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courier = widget.courierLocation;
    final target = widget.destination;
    if (courier == null || target == null) {
      return const SizedBox.shrink();
    }

    final courierPoint = LatLng(courier.latitude, courier.longitude);
    final destinationPoint = LatLng(target.latitude, target.longitude);
    final points = [courierPoint, destinationPoint];
    final pointsDiffer =
        courier.latitude != target.latitude ||
        courier.longitude != target.longitude;
    final initialCenter = LatLng(
      (courier.latitude + target.latitude) / 2,
      (courier.longitude + target.longitude) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14,
                initialCameraFit: pointsDiffer
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(44),
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
                MarkerLayer(
                  markers: [
                    Marker(
                      point: courierPoint,
                      width: 54,
                      height: 54,
                      child: const _MapPin(
                        icon: Icons.delivery_dining_rounded,
                        color: Color(0xFF087E75),
                      ),
                    ),
                    Marker(
                      point: destinationPoint,
                      width: 50,
                      height: 50,
                      child: const _MapPin(
                        icon: Icons.location_on_rounded,
                        color: Color(0xFFC2413B),
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
              top: 10,
              left: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendDot(color: Color(0xFF087E75)),
                      SizedBox(width: 5),
                      Text('Kurir'),
                      SizedBox(width: 12),
                      _LegendDot(color: Color(0xFFC2413B)),
                      SizedBox(width: 5),
                      Text('Tujuan'),
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
