import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseHelper {
  static final _databaseName = "products.db";
  static final _databaseVersion = 1;

  static final table = 'products';

  // Column names
  static final columnId = 'id';
  static final columnTradeName = 'trade_name';
  static final columnGenericName = 'generic_name';
  static final columnPharmacology = 'pharmacology';
  static final columnArabicName = 'arabic_name';
  static final columnPrice = 'price';
  static final columnCompany = 'company';
  static final columnDescription = 'description';
  static final columnRoute = 'route';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Secure Storage
  static final _secureStorage = FlutterSecureStorage();
  static const _dbPasswordKey = 'db_password';

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Get or generate encryption key
    String? password = await _secureStorage.read(key: _dbPasswordKey);
    if (password == null) {
      // Generate a secure random password
      password = _generateSecurePassword();
      await _secureStorage.write(key: _dbPasswordKey, value: password);
    }

    // Initialize database
    _database = await _initDatabase(password);
    return _database!;
  }

  Future<Database> _initDatabase(String password) async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      password: password,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTradeName TEXT NOT NULL,
        $columnGenericName TEXT NOT NULL,
        $columnPharmacology TEXT NOT NULL,
        $columnArabicName TEXT,
        $columnPrice REAL,
        $columnCompany TEXT NOT NULL,
        $columnDescription TEXT,
        $columnRoute TEXT NOT NULL
      )
    ''');
  }

  // Generate a secure random password (simple example)
  String _generateSecurePassword() {
    // In production, use a more secure method
    return 'secure_password_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Insert or update products
  Future<void> insertProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(
        table,
        product,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      table,
      where: '''
        $columnTradeName LIKE ? OR
        $columnGenericName LIKE ? OR
        $columnPharmacology LIKE ? OR
        $columnArabicName LIKE ? OR
        $columnCompany LIKE ? OR
        $columnDescription LIKE ? OR
        $columnRoute LIKE ?
      ''',
      whereArgs: List.filled(7, '%$query%'),
    );
  }

  // Get all products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query(table);
  }

  // Clear database
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(table);
  }
}
