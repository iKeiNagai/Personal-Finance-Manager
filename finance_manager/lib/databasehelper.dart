import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "personal_finance.db";
  static final _databaseVersion = 1;

  static final table = 'accounts';

  static final columnId = '_id';
  static final columnName = 'name';
  static final columnBalance = 'balance';
  static final columnType = 'Type';


  static final table2 = 'transactions';

  static final columnId_2 = 'id';
  static final columnAmount = 'amount';
  static final columnCategory = 'category';
  static final columnDate = 'date';
  static final foreignKey = 'account_id';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT NOT NULL,
            $columnBalance REAL NOT NULL,
            $columnType TEXT NOT NULL
          )
          ''');
    
    await db.execute('''
          CREATE TABLE $table2 (
            $columnId_2 INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnAmount REAL NOT NULL,
            $columnCategory TEXT NOT NULL,
            $columnDate TEXT NOT NULL,
            $foreignKey INTEGER NOT NULL,
            FOREIGN KEY ($foreignKey) REFERENCES $table($columnId) ON DELETE CASCADE
          )
          ''');
  }

  Future<int> insertTransaction(double? amount, String category, String date, int accountId) async {
    Database db = await instance.database;
    return await db.insert(table2,{
      columnAmount: amount,
      columnCategory: category,
      columnDate: date,
      foreignKey: accountId
    });
  }

  Future<List<Map<String, dynamic>>> queryAllRowsTransaction(int accountId) async {
    Database db = await instance.database;
    return await db.query(
      table2,
      where: '$foreignKey = ?',
      whereArgs: [accountId]);
  }

  // Insert new account
  Future<int> insert(String name, double? amount, String type) async {
    Database db = await instance.database;
    return await db.insert(table,{
      columnName: name,
      columnBalance: amount,
      columnType: type
    });
  }

  // Retrieve all accounts
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> updateAccountBalance(int accountId, double newBalance) async {
    Database db = await instance.database;
    return await db.update(table,{
      columnBalance : newBalance
    },
    where: '$columnId = ?',
    whereArgs: [accountId]
    );

  }
  // Update an account
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete an account
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await instance.database;
    return await db.delete(table2, where: '$columnId_2 = ?', whereArgs: [id]);
  }
}
