import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'schema.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartbill.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    final db = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await _executeBatchScript(db, initialSqlScript);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute('ALTER TABLE customers ADD COLUMN gst_number TEXT;');
              await db.execute('ALTER TABLE customers ADD COLUMN created_at TEXT;');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE sales ADD COLUMN customer_name TEXT;');
            } catch (_) {}
          }
          if (oldVersion < 3) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN gst_rate REAL DEFAULT 0;'); } catch (_) {}
            try { await db.execute('ALTER TABLE sales ADD COLUMN cgst_rate REAL DEFAULT 0;'); } catch (_) {}
            try { await db.execute('ALTER TABLE sales ADD COLUMN sgst_rate REAL DEFAULT 0;'); } catch (_) {}
            try { await db.execute('ALTER TABLE sales ADD COLUMN taxable_amount REAL DEFAULT 0;'); } catch (_) {}
            try { await db.execute('ALTER TABLE sales ADD COLUMN cgst_amount REAL DEFAULT 0;'); } catch (_) {}
            try { await db.execute('ALTER TABLE sales ADD COLUMN sgst_amount REAL DEFAULT 0;'); } catch (_) {}
          }
        },
      ),
    );

    // Migration helper: Ensure GST, barcode & bank detail columns exist
    try { await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN gst_rate REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN cgst_rate REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN sgst_rate REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN taxable_amount REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN cgst_amount REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE sales ADD COLUMN sgst_amount REAL DEFAULT 0;'); } catch (_) {}
    try { await db.execute('ALTER TABLE settings ADD COLUMN account_number TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE settings ADD COLUMN ifsc TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE settings ADD COLUMN branch TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE settings ADD COLUMN bank_name TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE settings ADD COLUMN account_type TEXT;'); } catch (_) {}

    // Wipe old sample data if present and populate new 572 weight-variant SK Masala catalog
    try {
      final catalogCheck = await db.rawQuery("SELECT COUNT(*) as count FROM products");
      final count = (catalogCheck.first.values.first as num?)?.toInt() ?? 0;
      if (count != 572) {
        await db.execute('DELETE FROM sale_items;');
        await db.execute('DELETE FROM sales;');
        await db.execute('DELETE FROM products;');
        await db.execute('DELETE FROM categories;');
        await _executeBatchScript(db, initialSqlScript);
      }
    } catch (e) {
      await _executeBatchScript(db, initialSqlScript);
    }

    // Auto-migrate historical sales records
    try {
      final unmigrated = await db.rawQuery("SELECT sale_id, subtotal, discount, gst FROM sales WHERE taxable_amount = 0 OR taxable_amount IS NULL");
      for (final row in unmigrated) {
        final id = row['sale_id'] as int;
        final subtotal = (row['subtotal'] as num?)?.toDouble() ?? 0.0;
        final discount = (row['discount'] as num?)?.toDouble() ?? 0.0;
        final gst = (row['gst'] as num?)?.toDouble() ?? 0.0;

        final taxable = (subtotal - discount).clamp(0.0, double.infinity);
        double rate = 0.0;
        if (gst > 0 && taxable > 0) {
          final approxRate = (gst / taxable) * 100;
          if (approxRate > 20) {
            rate = 28.0;
          } else if (approxRate > 15) {
            rate = 18.0;
          } else if (approxRate > 8) {
            rate = 12.0;
          } else if (approxRate > 2) {
            rate = 5.0;
          } else {
            rate = approxRate;
          }
        }
        final halfRate = rate / 2;
        final cgstAmt = gst / 2;
        final sgstAmt = gst / 2;

        await db.rawUpdate('''
          UPDATE sales SET
            gst_rate = ?,
            cgst_rate = ?,
            sgst_rate = ?,
            taxable_amount = ?,
            cgst_amount = ?,
            sgst_amount = ?
          WHERE sale_id = ?
        ''', [rate, halfRate, halfRate, taxable, cgstAmt, sgstAmt, id]);
      }
    } catch (_) {}

    return db;
  }

  Future<void> _executeBatchScript(Database db, String script) async {
    final statements = script
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    
    for (final statement in statements) {
      try {
        await db.execute(statement);
      } catch (e) {
        // Ignore duplicate inserts on re-init
      }
    }
  }

  // --- SETTINGS ---
  Future<Settings?> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings');
    if (result.isNotEmpty) {
      final s = Settings.fromMap(result.first);
      if (s.shopName == 'SK TRADERS' || s.phone == '0422-2345678' || !s.address.contains('Tiruchirappalli')) {
        final updated = Settings(
          shopName: 'MS TRADERS',
          address: '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli - 620002, Tamil Nadu, India.',
          phone: '7708906866',
          gstNumber: s.gstNumber.isEmpty ? '33ABCDE1234F1Z5' : s.gstNumber,
          invoicePrefix: s.invoicePrefix.isEmpty ? 'INV' : s.invoicePrefix,
          accountNumber: s.accountNumber,
          ifsc: s.ifsc,
          branch: s.branch,
          bankName: s.bankName,
          accountType: s.accountType,
        );
        await db.delete('settings');
        await db.insert('settings', updated.toMap());
        return updated;
      }
      return s;
    }
    final defaultSettings = Settings(
      shopName: 'MS TRADERS',
      address: '138, Mullai Street, Sanjeevi Nagar,\nTiruchirappalli - 620002, Tamil Nadu, India.',
      phone: '7708906866',
      gstNumber: '33ABCDE1234F1Z5',
      invoicePrefix: 'INV',
      accountNumber: '05390200000618',
      ifsc: 'BARB0TIRUCH',
      branch: 'TRICHY MAIN',
      bankName: 'BANK OF BARODA',
      accountType: 'CURRENT ACCOUNT',
    );
    await db.insert('settings', defaultSettings.toMap());
    return defaultSettings;
  }



  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'category_name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> getProductsCountForCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
      [categoryId],
    );
    if (result.isNotEmpty && result.first.values.isNotEmpty) {
      return (result.first.values.first as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<int> deleteCategory(int categoryId) async {
    final db = await instance.database;
    final count = await getProductsCountForCategory(categoryId);
    if (count > 0) {
      throw Exception('Cannot delete category with associated products.');
    }
    return await db.delete(
      'categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // --- PRODUCTS ---
  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'product_name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'product_id = ?',
      whereArgs: [product.productId],
    );
  }

  Future<int> deleteProduct(int productId) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> updateStock(int productId, int quantityChange) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE product_id = ?',
      [quantityChange, productId],
    );
  }

  // --- CUSTOMERS ---
  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'customer_name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'customer_id = ?',
      whereArgs: [customer.customerId],
    );
  }

  Future<int> deleteCustomer(int customerId) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  // --- SALES & SALE ITEMS ---
  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['sale_id'] = saleId;
        await txn.insert('sale_items', itemMap);
        // Decrease stock
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE product_id = ?',
          [item.quantity, item.productId],
        );
      }
      return saleId;
    });
  }

  Future<void> deleteSale(int saleId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Fetch sale items to restore stock
      final itemsResult = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      for (var row in itemsResult) {
        final item = SaleItem.fromMap(row);
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE product_id = ?',
          [item.quantity, item.productId],
        );
      }
      // 2. Delete items & sale
      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      await txn.delete('sales', where: 'sale_id = ?', whereArgs: [saleId]);
    });
  }

  Future<List<Sale>> getSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'date DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await instance.database;
    final result = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return result.map((json) => SaleItem.fromMap(json)).toList();
  }

  Future<void> resetToOfficialCatalog() async {
    final db = await instance.database;
    await db.execute('DELETE FROM sale_items;');
    await db.execute('DELETE FROM sales;');
    await db.execute('DELETE FROM products;');
    await db.execute('DELETE FROM categories;');
    await _executeBatchScript(db, initialSqlScript);
  }
}
