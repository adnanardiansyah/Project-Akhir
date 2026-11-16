import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/utils/format_rupiah.dart';

void main() {
  group('formatRupiah', () {
    test('nol dan angka kecil tanpa titik', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(500), 'Rp 500');
    });

    test('ribuan memakai titik', () {
      expect(formatRupiah(1000), 'Rp 1.000');
      expect(formatRupiah(15000), 'Rp 15.000');
      expect(formatRupiah(125000), 'Rp 125.000');
    });

    test('jutaan memakai dua titik', () {
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('bilangan negatif diberi tanda minus', () {
      expect(formatRupiah(-2500), '-Rp 2.500');
    });
  });
}
