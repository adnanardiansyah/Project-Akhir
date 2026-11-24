import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/utils/arrival_detector.dart';

void main() {
  final now = DateTime.utc(2026, 11, 24, 7, 0);
  const courierLatitude = 5.1801;
  const courierLongitude = 97.1507;
  const destinationLatitude = 5.18005;
  const destinationLongitude = 97.1506;

  bool observe(
    ArrivalDetector detector, {
    required double? speed,
    required DateTime at,
    double latitude = courierLatitude,
    double longitude = courierLongitude,
  }) => detector.observe(
    courierLatitude: latitude,
    courierLongitude: longitude,
    destinationLatitude: destinationLatitude,
    destinationLongitude: destinationLongitude,
    speedMetersPerSecond: speed,
    now: at,
  );

  group('ArrivalDetector', () {
    test('barang tiba setelah kurir diam 20 detik di radius tujuan', () {
      final detector = ArrivalDetector();
      expect(observe(detector, speed: 0.4, at: now), isFalse);
      expect(
        observe(detector, speed: 0.4, at: now.add(const Duration(seconds: 19))),
        isFalse,
      );
      expect(
        observe(detector, speed: 0.4, at: now.add(const Duration(seconds: 20))),
        isTrue,
      );
    });

    test('di luar radius tidak memicu tiba', () {
      final detector = ArrivalDetector();
      expect(
        observe(
          detector,
          speed: 0,
          at: now.add(const Duration(minutes: 1)),
          latitude: 5.181,
          longitude: 97.151,
        ),
        isFalse,
      );
    });

    test('kurir bergerak lagi membuat hitungan diam diulang', () {
      final detector = ArrivalDetector();
      expect(observe(detector, speed: 0, at: now), isFalse);
      expect(
        observe(
          detector,
          speed: 4,
          at: now.add(const Duration(seconds: 5)),
          latitude: 5.1804,
        ),
        isFalse,
      );
      expect(
        observe(
          detector,
          speed: 0,
          at: now.add(const Duration(seconds: 10)),
          latitude: 5.1804,
        ),
        isFalse,
      );
      expect(
        observe(
          detector,
          speed: 0,
          at: now.add(const Duration(seconds: 24)),
          latitude: 5.1804,
        ),
        isFalse,
      );
      expect(
        observe(
          detector,
          speed: 0,
          at: now.add(const Duration(seconds: 25)),
          latitude: 5.1804,
        ),
        isTrue,
      );
    });

    test('jitter kecepatan GPS tidak membatalkan hitungan diam', () {
      final detector = ArrivalDetector();
      expect(observe(detector, speed: 0, at: now), isFalse);
      expect(
        observe(detector, speed: 5, at: now.add(const Duration(seconds: 5))),
        isFalse,
      );
      expect(
        observe(detector, speed: 0, at: now.add(const Duration(seconds: 20))),
        isTrue,
      );
    });
  });
}
