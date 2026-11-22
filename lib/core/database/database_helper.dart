import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ktsms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        threadId TEXT,
        address TEXT NOT NULL,
        body TEXT NOT NULL,
        date INTEGER NOT NULL,
        type INTEGER NOT NULL,
        read INTEGER NOT NULL,
        category TEXT DEFAULT 'Personal'
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL,
        dueDate INTEGER NOT NULL,
        sender TEXT,
        category TEXT,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertMessage(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    return await db.query('messages', orderBy: 'date DESC');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
