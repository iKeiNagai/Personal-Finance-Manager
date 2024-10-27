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
  static final columnExpense = 'isExpense';
  static final foreignKey = 'account_id';

  // New table for stocks
  static final stocksTable = 'stocks';

  // Columns for stocks table
  static final columnStockId = 'stock_id';
  static final columnTicker = 'ticker';
  static final columnQuantity = 'quantity';
  static final columnPurchasePrice = 'purchase_price';
  static final columnPurchaseDate = 'purchase_date';
  static final columnCurrentPrice = 'current_price';

  static const String tableStockPositions = 'stock_positions';

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
            $columnExpense INTEGER NOT NULL,
            $foreignKey INTEGER NOT NULL,
            FOREIGN KEY ($foreignKey) REFERENCES $table($columnId) ON DELETE CASCADE
          )
          ''');
    await db.execute('''
      CREATE TABLE $stocksTable (
        $columnStockId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTicker TEXT NOT NULL,
        $columnQuantity REAL NOT NULL,
        $columnPurchasePrice REAL NOT NULL,
        $columnPurchaseDate TEXT NOT NULL,
        $columnCurrentPrice REAL
      )
    ''');
  }

  // Insert new stock position
  Future<int> insertStock(String ticker, double quantity, double purchasePrice) async {
    Database db = await instance.database;
    return await db.insert(stocksTable, {
      columnTicker: ticker,
      columnQuantity: quantity,
      columnPurchasePrice: purchasePrice,
      columnPurchaseDate: DateTime.now().toString(),
      columnCurrentPrice: purchasePrice, // Initial current price
    });
  }


  // Retrieve all stocks
  Future<List<Map<String, dynamic>>> queryAllStocks() async {
    Database db = await instance.database;
    return await db.query(stocksTable);
  }

  Future<List<Map<String, dynamic>>> queryAllStockPositions() async {
    final db = await database;
    final result = await db.query(DatabaseHelper.tableStockPositions);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<int> deleteStockPosition(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseHelper.tableStockPositions,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // Update stock
  Future<int> updateStock(int stockId, double newQuantity, double newPurchasePrice,) async {
    Database db = await instance.database;
    return await db.update(stocksTable, {
      columnQuantity: newQuantity,
      columnPurchasePrice: newPurchasePrice,

    }, where: '$columnStockId = ?', whereArgs: [stockId]);
  }

  // Delete stock
  Future<int> deleteStock(int stockId) async {
    Database db = await instance.database;
    return await db.delete(stocksTable, where: '$columnStockId = ?', whereArgs: [stockId]);
  }

  // Future<void> preloadDatabase() async {
  //   Database db = await instance.database;
  //   await db.insert(stocksTable, {
  //     columnTicker: 'TQQQ',
  //     columnQuantity: 110.0,
  //     columnPurchasePrice: 62.0,
  //     columnPurchaseDate: DateTime.now().toString(),
  //     columnCurrentPrice: 62.0,
  //   });
  // }


    Future<int> insertTransaction(double? amount, String category, String date,bool isExpense,int accountId) async {
    Database db = await instance.database;
    return await db.insert(table2,{
      columnAmount: amount,
      columnCategory: category,
      columnDate: date,
      columnExpense: isExpense ? 1 : 0,
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

  Future<int> updateTransaction(int transactionId, double newAmount, String newCategory, String newDate, bool isExpense) async {
    Database db = await instance.database;

    return await db.update(table2,{
      columnAmount : newAmount,
      columnCategory : newCategory,
      columnDate : newDate,
      columnExpense :isExpense
    },
    where: '$columnId_2 = ?',
    whereArgs: [transactionId]);
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

  Future<int> deleteAllTransactionsAccount(int accountId) async {
    Database db = await instance.database;
    return await db.delete(
      table2, 
      where: '$foreignKey = ?', 
      whereArgs: [accountId],
    );
  }
  Future<List<Map<String, dynamic>>> getMonthlyReport() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', $columnDate) AS month,
        SUM(CASE WHEN $columnExpense = 1 THEN $columnAmount ELSE 0 END) AS total_expenses,
        SUM(CASE WHEN $columnExpense = 0 THEN $columnAmount ELSE 0 END) AS total_income 
      FROM 
        $table2 
      GROUP BY 
        month
      ORDER BY 
        month DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getYearlyReport() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        strftime('%Y', $columnDate) AS year,
        SUM(CASE WHEN $columnExpense = 1 THEN $columnAmount ELSE 0 END) AS total_expenses,
        SUM(CASE WHEN $columnExpense = 0 THEN $columnAmount ELSE 0 END) AS total_income 
      FROM 
        $table2 
      GROUP BY 
        year
      ORDER BY 
        year DESC
    ''');
  }


}
