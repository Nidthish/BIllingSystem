import 'package:flutter_test/flutter_test.dart';
import 'package:smartbill/database/schema.dart';

void main() {
  test('initialSqlScript contains 143 product inserts', () {
    final productInsertMatches = RegExp(r"\('([^']+)',\s*(\d+),\s*0\.0,\s*0\.0,\s*1000,\s*5,\s*0\.0,\s*'g',\s*'([^']+)'\)").allMatches(initialSqlScript);
    expect(productInsertMatches.length, equals(143));

    // Verify product code SK002
    final sk002Products = productInsertMatches.where((m) => m.group(3) == 'SK002').toList();
    expect(sk002Products.length, equals(1));

    final sk002Names = sk002Products.map((m) => m.group(1)).toList();
    expect(sk002Names, contains('Chettinad Chicken Masala'));
  });
}
