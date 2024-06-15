import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "myDatabase.db";
  static const _databaseVersion = 1;

  static const table = 'cards';

  static const columnId = 'id';
  static const columnWord = 'word';
  static const columnMainMeaning = 'main_meaning';
  static const columnSubMeaning = 'sub_meaning';
  static const columnSentence = 'sentence';
  static const columnSentenceJp = 'sentence_jp';

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
            $columnId INTEGER PRIMARY KEY,
            $columnWord TEXT NOT NULL,
            $columnMainMeaning TEXT,
            $columnSubMeaning TEXT,
            $columnSentence TEXT,
            $columnSentenceJp TEXT
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    final rows = await db.query(table);
    print('Queried ${rows.length} rows'); // デバッグメッセージ追加
    return rows;
  }

  // New search method
  Future<List<Map<String, dynamic>>> searchWord(String keyword) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      table,
      where: '$columnWord LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return result;
  }
}
