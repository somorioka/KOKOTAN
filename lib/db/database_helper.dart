import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kokotan/Algorithm/srs.dart';

class DatabaseHelper {
  static const _databaseName = "myDatabase.db";
  static const _databaseVersion = 2;

  static const wordTable = 'words';
  static const cardTable = 'cards';
  static const queueTable = 'queues'; // 新しく追加するテーブル

  // Word table columns
  static const columnId = 'id';
  static const columnWord = 'word';
  static const columnWordVoice = 'word_voice';
  static const columnPronunciation = 'pronunciation';
  static const columnMainMeaning = 'main_meaning';
  static const columnSubMeaning = 'sub_meaning';
  static const columnSentence = 'sentence';
  static const columnSentenceVoice = 'sentence_voice';
  static const columnSentenceJp = 'sentence_jp';

  // Card table columns
  static const cardColumnId = 'id';
  static const cardColumnWordId = 'word_id';
  static const cardColumnDue = 'due';
  static const cardColumnCrt = 'crt';
  static const cardColumnType = 'type';
  static const cardColumnQueue = 'queue';
  static const cardColumnIvl = 'ivl';
  static const cardColumnFactor = 'factor';
  static const cardColumnReps = 'reps';
  static const cardColumnLapses = 'lapses';
  static const cardColumnLeft = 'left';

  // Queue table columns
  static const queueColumnId = 'id';
  static const queueColumnCardId = 'card_id';
  static const queueColumnType = 'queue_type';
  // 0 = newQueue, 2 = revQueueとする。1のlrnQueueは今回使わないので注意。
  //card_idを使って、カードをQueueに保存していく。

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
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // マイグレーションの設定
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $wordTable (
            $columnId INTEGER PRIMARY KEY,
            $columnWord TEXT NOT NULL,
            $columnWordVoice TEXT,
            $columnPronunciation TEXT,
            $columnMainMeaning TEXT,
            $columnSubMeaning TEXT,
            $columnSentence TEXT,
            $columnSentenceVoice TEXT,
            $columnSentenceJp TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $cardTable (
            $cardColumnId INTEGER PRIMARY KEY,
            $cardColumnWordId INTEGER NOT NULL,
            $cardColumnDue INTEGER,
            $cardColumnCrt INTEGER,
            $cardColumnType INTEGER,
            $cardColumnQueue INTEGER,
            $cardColumnIvl INTEGER,
            $cardColumnFactor INTEGER,
            $cardColumnReps INTEGER,
            $cardColumnLapses INTEGER,
            $cardColumnLeft INTEGER,
            FOREIGN KEY ($cardColumnWordId) REFERENCES $wordTable ($columnId)
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // `queues`テーブルを追加するSQLコマンド
      await db.execute('''
      CREATE TABLE $queueTable (
        $queueColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $queueColumnCardId INTEGER NOT NULL,
        $queueColumnType INTEGER NOT NULL,
        FOREIGN KEY ($queueColumnCardId) REFERENCES $cardTable ($cardColumnId)
      )
    ''');
    }
  }

  Future<int> insertWord(Word word) async {
    Database db = await instance.database;
    return await db.insert(wordTable, word.toMap());
  }

  Future<int> insertCard(Card card) async {
    Database db = await instance.database;
    return await db.insert(cardTable, card.toMap());
  }

  Future<int> insertCardToQueue(int cardId, int queueType) async {
    Database db = await instance.database;
    return await db.insert(queueTable, {
      queueColumnCardId: cardId,
      queueColumnType: queueType,
    });
  }

  Future<int> removeCardFromQueue(int cardId, int queueType) async {
    Database db = await instance.database;
    return await db.delete(
      queueTable,
      where: '$queueColumnCardId = ? AND $queueColumnType = ?',
      whereArgs: [cardId, queueType],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllWords() async {
    Database db = await instance.database;
    final rows = await db.query(wordTable);
    print('Queried ${rows.length} rows'); // デバッグメッセージ追加
    return rows;
  }

  Future<List<Map<String, dynamic>>> queryAllCards() async {
    Database db = await instance.database;
    final rows = await db.query(cardTable);
    print('Queried ${rows.length} rows'); // デバッグメッセージ追加
    return rows;
  }

  Future<List<Map<String, dynamic>>> queryCardsInQueue(int queueType) async {
    Database db = await instance.database;
    final rows = await db.query(queueTable,
        where: '$queueColumnType = ?', whereArgs: [queueType]);
    print('Queried ${rows.length} rows from queue'); // デバッグメッセージ追加
    return rows;
  }

  Future<int> updateWord(Word word) async {
    Database db = await instance.database;
    return await db.update(
      wordTable,
      word.toMap(),
      where: '$columnId = ?',
      whereArgs: [word.id],
    );
  }

  Future<int> updateCard(Card card) async {
    Database db = await instance.database;
    return await db.update(
      cardTable,
      card.toMap(),
      where: '$cardColumnId = ?',
      whereArgs: [card.id],
    );
  }

  Future<bool> doesWordExist(int wordId) async {
    Database db = await instance.database;
    var result = await db.query(
      wordTable,
      where: 'id = ?',
      whereArgs: [wordId],
    );
    return result.isNotEmpty;
  }
}
