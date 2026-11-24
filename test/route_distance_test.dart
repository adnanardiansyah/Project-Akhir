import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/services/route_distance_service.dart';
import 'package:food_order_app/utils/format_distance.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

// Potongan respons asli ORS (docs/bukti/l7_ors_contoh_respons.json) untuk resto1 ke resto2
const _orsSample =
    '{"type": "FeatureCollection", "features": [{"type": "Feature", '
    '"properties": {"summary": {"distance": 2280.7, "duration": 292.1}}, '
    '"geometry": {"type": "LineString", "coordinates": '
    '[[97.1507, 5.1801], [97.1460, 5.1789], [97.1390, 5.1790]]}}]}';

const _resto1 = GeoPoint(5.1801, 97.1507);
const _resto2 = GeoPoint(5.179, 97.139);

void main() {
  group('formatDistance', () {
    test('di bawah 1 km ditulis dalam meter', () {
      expect(formatDistance(0), '0 m');
      expect(formatDistance(849.6), '850 m');
    });

    test('1 km ke atas ditulis km satu desimal dengan koma', () {
      expect(formatDistance(1000), '1,0 km');
      expect(formatDistance(2280.7), '2,3 km');
      expect(formatDistance(15449), '15,4 km');
    });
  });

  group('parseRouteDistanceMeters', () {
    test('membaca summary.distance dari respons ORS asli', () {
      expect(parseRouteDistanceMeters(jsonDecode(_orsSample)), 2280.7);
    });

    test('bentuk respons tidak sesuai menghasilkan null', () {
      expect(parseRouteDistanceMeters(null), isNull);
      expect(parseRouteDistanceMeters({'features': []}), isNull);
      expect(
        parseRouteDistanceMeters({
          'features': [
            {'properties': {}},
          ],
        }),
        isNull,
      );
      expect(
        parseRouteDistanceMeters({
          'error': {'code': 2010, 'message': 'Could not find routable point'},
        }),
        isNull,
      );
    });
  });

  group('parseRouteInfo', () {
    test('membaca durasi dan polyline dari geometry ORS', () {
      final info = parseRouteInfo(jsonDecode(_orsSample));
      expect(info, isNotNull);
      expect(info!.distanceMeters, 2280.7);
      expect(info.duration, const Duration(seconds: 292));
      expect(info.polyline, [
        const LatLng(5.1801, 97.1507),
        const LatLng(5.1789, 97.1460),
        const LatLng(5.1790, 97.1390),
      ]);
    });

    test('tanpa geometry tetap menghasilkan rute dengan polyline kosong', () {
      final info = parseRouteInfo({
        'features': [
          {
            'properties': {
              'summary': {'distance': 100, 'duration': 60},
            },
          },
        ],
      });
      expect(info?.distanceMeters, 100);
      expect(info?.duration, const Duration(seconds: 60));
      expect(info?.polyline, isEmpty);
    });

    test('durasi tidak valid menghasilkan null', () {
      expect(
        parseRouteInfo({
          'features': [
            {
              'properties': {
                'summary': {'distance': 100, 'duration': 'lama'},
              },
            },
          ],
        }),
        isNull,
      );
    });
  });

  group('RouteDistanceService', () {
    test('mengirim key lewat header dan koordinat lon,lat', () async {
      late http.Request captured;
      final service = RouteDistanceService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(_orsSample, 200);
        }),
      );
      service.setPersonalApiKey('kunci-uji');

      final meters = await service.distanceMeters(_resto1, _resto2);

      expect(meters, 2280.7);
      expect(captured.headers['Authorization'], 'kunci-uji');
      expect(captured.url.host, 'api.heigit.org');
      expect(captured.url.path, '/openrouteservice/v2/directions/driving-car');
      expect(captured.url.queryParameters['start'], '97.1507,5.1801');
      expect(captured.url.queryParameters['end'], '97.139,5.179');
      expect(captured.url.queryParameters['geometries'], 'geojson');
      expect(captured.url.queryParameters['overview'], 'full');
      expect(captured.url.queryParameters.containsKey('api_key'), isFalse);
    });

    test('pasangan titik yang sama hanya meminta sekali per sesi', () async {
      var calls = 0;
      final service = RouteDistanceService(
        client: MockClient((_) async {
          calls++;
          return http.Response(_orsSample, 200);
        }),
      );
      service.setPersonalApiKey('kunci-uji');

      await service.distanceMeters(_resto1, _resto2);
      await service.distanceMeters(_resto1, _resto2);

      expect(calls, 1);
    });

    test('mengganti key membuang cache dan memakai key baru', () async {
      final headers = <String>[];
      final service = RouteDistanceService(
        client: MockClient((request) async {
          headers.add(request.headers['Authorization']!);
          return http.Response(_orsSample, 200);
        }),
      );
      service.setPersonalApiKey('key-pertama');
      await service.distanceMeters(_resto1, _resto2);

      service.setPersonalApiKey('key-kedua');
      await service.distanceMeters(_resto1, _resto2);

      expect(headers, ['key-pertama', 'key-kedua']);
    });

    for (final code in [401, 403, 404, 429, 500]) {
      test('status $code menghasilkan jarak tidak tersedia', () async {
        final service = RouteDistanceService(
          client: MockClient((_) async => http.Response('{}', code)),
        );
        service.setPersonalApiKey('kunci-uji');
        expect(await service.distanceMeters(_resto1, _resto2), isNull);
      });
    }

    test(
      'kegagalan tidak disimpan, permintaan berikutnya dicoba lagi',
      () async {
        var calls = 0;
        final service = RouteDistanceService(
          client: MockClient((_) async {
            calls++;
            return calls == 1
                ? http.Response('{}', 429)
                : http.Response(_orsSample, 200);
          }),
        );
        service.setPersonalApiKey('kunci-uji');

        expect(await service.distanceMeters(_resto1, _resto2), isNull);
        expect(await service.distanceMeters(_resto1, _resto2), 2280.7);
        expect(calls, 2);
      },
    );

    test('galat jaringan menghasilkan jarak tidak tersedia', () async {
      final service = RouteDistanceService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      service.setPersonalApiKey('kunci-uji');
      expect(await service.distanceMeters(_resto1, _resto2), isNull);
    });

    test(
      'key dihapus setelah sesi berakhir dan harus dimasukkan lagi',
      () async {
        var calls = 0;
        final service = RouteDistanceService(
          client: MockClient((_) async {
            calls++;
            return http.Response(_orsSample, 200);
          }),
        );
        service.setPersonalApiKey('kunci-sesi');
        expect(await service.distanceMeters(_resto1, _resto2), 2280.7);

        service.clearPersonalApiKey();
        expect(service.hasPersonalApiKey, isFalse);
        expect(await service.distanceMeters(_resto1, _resto2), isNull);
        expect(calls, 1);
      },
    );

    test('tanpa key tidak meminta ke server', () async {
      var calls = 0;
      final service = RouteDistanceService(
        client: MockClient((_) async {
          calls++;
          return http.Response(_orsSample, 200);
        }),
      );
      expect(await service.distanceMeters(_resto1, _resto2), isNull);
      expect(calls, 0);
    });
  });
}
