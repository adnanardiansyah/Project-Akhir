import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/widgets/food_image.dart';
import 'package:food_order_app/widgets/restaurant_avatar.dart';

void main() {
  group('getFoodItemPhoto', () {
    test('menu utama memakai foto hidangan yang sesuai', () {
      expect(getFoodItemPhoto('Mie Bangladesh'), contains('37173529'));
      expect(
        getFoodItemPhoto('Mie Bangladesh Kuah Becek'),
        contains('37173529'),
      );
      expect(getFoodItemPhoto('Chicken Teriyaki'), contains('38714625'));
      expect(getFoodItemPhoto('Beef Teriyaki'), contains('17308547'));
      expect(getFoodItemPhoto('Naskot Ayam Penyet'), contains('37076558'));
    });

    test('menu tambahan Mie Bangladesh memakai foto yang sesuai', () {
      expect(getFoodItemPhoto('Mie Rebus Bangladesh'), contains('37173529'));
      expect(getFoodItemPhoto('Mie Goreng Basah Daging'), contains('40756021'));
      expect(getFoodItemPhoto('Kari Kambing'), contains('28674565'));
      expect(getFoodItemPhoto('Roti Cane'), contains('38954055'));
      expect(getFoodItemPhoto('Martabak Telur'), contains('41197492'));
    });

    test('menu HokBen memakai foto yang sesuai', () {
      expect(getFoodItemPhoto('Chicken Yakiniku'), contains('13065185'));
      expect(getFoodItemPhoto('Beef Yakiniku'), contains('37274310'));
      expect(
        getFoodItemPhoto('Simple Set Chicken Teriyaki 1'),
        contains('39083061'),
      );
      expect(
        getFoodItemPhoto('Hokkaido Miso Ramen Reguler'),
        contains('37415849'),
      );
      expect(getFoodItemPhoto('Tori Ball'), contains('28371785'));
      expect(getFoodItemPhoto('Ebi Furai'), contains('7011610'));
      expect(getFoodItemPhoto('Teh Kotak Sosro'), contains('4071422'));
      expect(getFoodItemPhoto('Fresh Orange Juice'), contains('37026953'));
    });

    test('menu Wong Solo memakai foto yang sesuai', () {
      expect(getFoodItemPhoto('Paket Ayam Bakar'), contains('14098784'));
      expect(getFoodItemPhoto('Naskot Lombok Ijo'), contains('37179941'));
      expect(getFoodItemPhoto('Naskot Nila Bakar'), contains('37255814'));
      expect(getFoodItemPhoto('Nasi Goreng Ayam'), contains('37173548'));
      expect(getFoodItemPhoto('Mie Goreng Biasa'), contains('37106132'));
      expect(getFoodItemPhoto('Es Jeruk Nipis'), contains('37026953'));
      expect(getFoodItemPhoto('Es Kopi Susu'), contains('5567620'));
      expect(getFoodItemPhoto('Cah Brokoli'), contains('21482825'));
      expect(getFoodItemPhoto('Tumis Kangkung'), contains('7361029'));
      expect(getFoodItemPhoto('Balado Cumi'), contains('30749018'));
      expect(getFoodItemPhoto('Nasi Putih'), contains('17563535'));
    });

    test('variasi menu mie memakai foto yang sesuai', () {
      expect(getFoodItemPhoto('Mie Aceh'), contains('37173529'));
      expect(getFoodItemPhoto('Mie Aceh Goreng'), contains('37106132'));
      expect(getFoodItemPhoto('Mie Kuah'), contains('37173529'));
      expect(getFoodItemPhoto('Mie Rebus'), contains('37173531'));
      expect(getFoodItemPhoto('Mie Goreng'), contains('37106132'));
      expect(getFoodItemPhoto('Mie Ayam'), contains('37104346'));
    });

    test('minuman dan menu lain memakai foto yang sesuai', () {
      expect(getFoodItemPhoto('Chicken Teriyaki Set'), contains('38714625'));
      expect(getFoodItemPhoto('Kopi Aceh'), contains('30839009'));
      expect(getFoodItemPhoto('Teh Tarik'), contains('4071422'));
      expect(getFoodItemPhoto('Es Jeruk'), contains('37026953'));
      expect(getFoodItemPhoto('Jus Jeruk'), contains('37026953'));
      expect(getFoodItemPhoto('Burger'), contains('3219483'));
      expect(getFoodItemPhoto('Pizza'), contains('35760004'));
    });

    test('nama dinormalisasi dan menu tak dikenal memakai foto umum', () {
      expect(getFoodItemPhoto('  mie   BANGLADESH  '), contains('37173529'));
      expect(getFoodItemPhoto('Menu Baru'), contains('5865071'));
    });
  });

  group('getRestaurantCoverPhoto', () {
    test('foto sampul mengikuti nama restoran', () {
      expect(getRestaurantCoverPhoto('Mie Bangladesh'), contains('37048267'));
      expect(
        getRestaurantCoverPhoto('HokBen - Suzuya Mall Lhokseumawe'),
        contains('38714625'),
      );
      expect(
        getRestaurantCoverPhoto('Ayam Penyet Wong Solo Lhokseumawe'),
        contains('37320407'),
      );
    });

    test('nama restoran dinormalisasi sebelum dicocokkan', () {
      expect(
        getRestaurantCoverPhoto('  mie   BANGLADESH  '),
        contains('37048267'),
      );
      expect(getRestaurantCoverPhoto('Kedai Kopi Aceh'), contains('15891300'));
    });

    test('nama restoran lain memakai foto sampul umum', () {
      expect(getRestaurantCoverPhoto('Resto Baru'), contains('5865071'));
    });
  });

  group('getRestaurantIcon', () {
    test('ikon mengikuti jenis restoran', () {
      expect(getRestaurantIcon('Mie Bangladesh'), Icons.ramen_dining_rounded);
      expect(
        getRestaurantIcon('HokBen - Suzuya Mall Lhokseumawe'),
        Icons.lunch_dining_rounded,
      );
      expect(
        getRestaurantIcon('Ayam Penyet Wong Solo Lhokseumawe'),
        Icons.rice_bowl_rounded,
      );
      expect(getRestaurantIcon('Kedai Kopi Aceh'), Icons.local_cafe_rounded);
    });

    test('nama yang tidak dikenal tidak dipaksa memakai ikon tertentu', () {
      expect(getRestaurantIcon('Resto Baru'), isNull);
    });
  });
}
