import 'package:flutter_test/flutter_test.dart';
import 'package:smartbill/database/schema.dart';

void main() {
  test('initialSqlScript contains 572 product inserts', () {
    final productInsertMatches = RegExp(r"\('([^']+)',\s*(\d+),\s*0\.0,\s*0\.0,\s*0,\s*5,\s*0\.0,\s*'pcs',\s*'([^']+)'\)").allMatches(initialSqlScript);
    expect(productInsertMatches.length, equals(572));

    // Verify product code SK002 has 4 weight variants
    final sk002Products = productInsertMatches.where((m) => m.group(3) == 'SK002').toList();
    expect(sk002Products.length, equals(4));

    final sk002Names = sk002Products.map((m) => m.group(1)).toList();
    expect(sk002Names, contains('Chettinad Chicken Masala (250g)'));
    expect(sk002Names, contains('Chettinad Chicken Masala (500g)'));
    expect(sk002Names, contains('Chettinad Chicken Masala (750g)'));
    expect(sk002Names, contains('Chettinad Chicken Masala (1kg)'));
  });
}
