import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kokotan/Algorithm/srs.dart'; // Card, Wordクラスを使う

class DatabaseHelper {
  static const _databaseName = "myDatabase.db";
  static const _databaseVersion = 1;

  static const wordTable = 'words';
  static const cardTable = 'cards';

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

  // 新しいカラム
  static const columnEnglishDefinition = 'english_definition'; // 英英
  static const columnEtymology = 'etymology'; // 語源
  static const columnMemo = 'memo'; // メモ
  static const columnImageUrl = 'image_url'; // 画像URL

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
  static const cardColumnDeckId = 'deck_id';

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
      pronunciation TEXT,
      main_meaning TEXT,
      sub_meaning TEXT,
      sentence TEXT,
      sentence_jp TEXT,
      word_voice TEXT,
      sentence_voice TEXT,
      english_definition TEXT,
      etymology TEXT,
      memo TEXT,
      image_url TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $cardTable (
      id INTEGER PRIMARY KEY,
      word_id INTEGER NOT NULL,
      deck_id INTEGER NOT NULL,
      due INTEGER,
      crt INTEGER,
      type INTEGER,
      queue INTEGER,
      ivl INTEGER,
      factor INTEGER,
      reps INTEGER,
      lapses INTEGER,
      left INTEGER,
      FOREIGN KEY (word_id) REFERENCES $wordTable (id)
    )
    ''');
  }

  // データの挿入
  Future<int> insertWord(Word word) async {
    Database db = await instance.database;
    return await db.insert(wordTable, word.toMap());
  }

  Future<int> insertCard(Card card) async {
    Database db = await instance.database;
    return await db.insert(cardTable, card.toMap());
  }

  // データの更新
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

  // Word の音声パスを更新するメソッド
  Future<void> updateWordVoicePaths(
      int wordId, String wordVoicePath, String sentenceVoicePath) async {
    Database db = await instance.database;

    await db.update(
      wordTable,
      {
        columnWordVoice: wordVoicePath,
        columnSentenceVoice: sentenceVoicePath,
      },
      where: '$columnId = ?',
      whereArgs: [wordId],
    );
  }

  // 全データの取得
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

  // IDを使ってカードを取得
  Future<Card?> queryCardById(int id) async {
    Database db = await instance.database;

    // カード情報を取得
    final cardResult = await db.query(
      cardTable,
      where: '$cardColumnId = ?',
      whereArgs: [id],
    );

    if (cardResult.isNotEmpty) {
      // カードに紐づくWord情報を取得
      final wordId = cardResult.first[cardColumnWordId];
      final wordResult = await db.query(
        wordTable,
        where: '$columnId = ?',
        whereArgs: [wordId],
      );

      if (wordResult.isNotEmpty) {
        // Wordとカードのデータを使ってCardを作成
        Word word = Word.fromMap(wordResult.first); // WordのfromMapを使用
        return Card.fromMap(cardResult.first, word); // CardのfromMapを使用
      }
    }

    return null; // カードまたはWordが見つからなければnullを返す
  }

// 特定の `wordID` でカードが存在するか確認
  Future<bool> doesCardExistWithWord(int wordId) async {
    final db = await database;
    var result = await db.query(
      cardTable,
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
    return result.isNotEmpty;
  }
}
