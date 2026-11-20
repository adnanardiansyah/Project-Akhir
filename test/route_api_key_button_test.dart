import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/services/route_distance_service.dart';
import 'package:food_order_app/widgets/route_api_key_button.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('key pribadi dipasang dan dihapus untuk sesi berjalan', (
    tester,
  ) async {
    final service = RouteDistanceService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [RouteApiKeyButton(service: service)]),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Masukkan kunci jarak'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), ' key-uji ');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(service.hasPersonalApiKey, isTrue);

    await tester.tap(find.byTooltip('Ubah kunci jarak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(service.hasPersonalApiKey, isFalse);
    service.dispose();
  });
}
