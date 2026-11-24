import 'package:latlong2/latlong.dart';

class ArrivalDetector {
  ArrivalDetector({
    this.radiusMeters = 60,
    this.holdDuration = const Duration(seconds: 20),
    this.maxSpeedMetersPerSecond = 1.5,
    this.jitterRadiusMeters = 15,
  });

  final double radiusMeters;
  final Duration holdDuration;
  final double maxSpeedMetersPerSecond;
  final double jitterRadiusMeters;

  LatLng? _reference;
  DateTime? _insideSince;

  bool observe({
    required double courierLatitude,
    required double courierLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required double? speedMetersPerSecond,
    required DateTime now,
  }) {
    final current = LatLng(courierLatitude, courierLongitude);
    const distance = Distance();
    final toDestination = distance.as(
      LengthUnit.Meter,
      current,
      LatLng(destinationLatitude, destinationLongitude),
    );
    if (toDestination > radiusMeters) {
      reset();
      return false;
    }

    final settled =
        speedMetersPerSecond != null &&
        speedMetersPerSecond >= 0 &&
        speedMetersPerSecond <= maxSpeedMetersPerSecond;
    if (!settled && _reference == null) {
      reset();
      return false;
    }

    final reference = _reference;
    if (reference == null) {
      _reference = current;
      _insideSince = now;
      return false;
    }

    // Jitter kecepatan GPS diabaikan selama posisi tidak berpindah jauh.
    if (distance.as(LengthUnit.Meter, reference, current) >
        jitterRadiusMeters) {
      _reference = current;
      _insideSince = now;
      return false;
    }

    return now.difference(_insideSince!) >= holdDuration;
  }

  void reset() {
    _reference = null;
    _insideSince = null;
  }
}
