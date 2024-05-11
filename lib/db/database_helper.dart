import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "Kokotan.db";
  static final _databaseVersion = 1;

  // シングルトンクラスとして実装
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // DBを開くまたは作成する
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // DBが存在しないときに呼ばれる
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY,
            note_id INTEGER,
            type INTEGER,
            queue INTEGER,
            interval INTEGER,
            factor REAL,
            reps INTEGER,
            lapses INTEGER,
            left INTEGER,
            due TEXT
          )
          ''');
  }
}
