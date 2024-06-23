import 'package:kokotan/Algorithm/srs.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "myDatabase.db";
  static const _databaseVersion = 1;

  static const wordTable = 'words';
  static const cardTable = 'cards';

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
          CREATE TABLE $wordTable (
            id INTEGER PRIMARY KEY,
            word TEXT NOT NULL,
            mainMeaning TEXT,
            subMeaning TEXT,
            sentence TEXT,
            sentenceJp TEXT
          )
          ''');
    await db.execute('''
          CREATE TABLE $cardTable (
            id INTEGER PRIMARY KEY,
            wordId INTEGER NOT NULL,
            due INTEGER,
            crt INTEGER,
            type INTEGER,
            queue INTEGER,
            ivl INTEGER,
            factor INTEGER,
            reps INTEGER,
            lapses INTEGER,
            left INTEGER,
            FOREIGN KEY (wordId) REFERENCES $wordTable (id)
          )
          ''');
  }

  Future<int> insertWord(Word word) async {
    Database db = await instance.database;
    return await db.insert(wordTable, word.toMap());
  }

  Future<int> insertCard(Card card) async {
    Database db = await instance.database;
    return await db.insert(cardTable, card.toMap());
  }

  Future<int> updateCard(Card card) async {
    Database db = await instance.database;
    return await db.update(
      cardTable,
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllWords() async {
    Database db = await instance.database;
    return await db.query(wordTable);
  }

  Future<List<Map<String, dynamic>>> queryAllCards() async {
    Database db = await instance.database;
    return await db.query(cardTable);
  }

  Future<List<Map<String, dynamic>>> searchWord(String keyword) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      wordTable,
      where: 'word LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return result;
  }
}
