import 'package:flutter_test/flutter_test.dart';
import 'package:smartbill/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('SmartBill App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBillApp());
    expect(find.byType(SmartBillApp), findsOneWidget);
  });
}
