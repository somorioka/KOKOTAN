import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:kokotan/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 新規カードの表示順設定
const int NEW_CARDS_DISTRIBUTE = 0;
const int NEW_CARDS_LAST = 1;
const int NEW_CARDS_FIRST = 2;

// プロモーション時の初期ファクター
const int STARTING_FACTOR = 2500;

/// ユーティリティ関数
int intTime({int scale = 1}) {
  return clock.now().millisecondsSinceEpoch ~/ scale;
}

int intId() {
  int t = intTime(scale: 1000);
  // 次の呼び出しが異なる値を返すことを保証
  while (intTime(scale: 1000) == t) {
    Future.delayed(Duration(milliseconds: 1));
  }
  return t;
}

/// デフォルトのコレクション設定
final Map<String, dynamic> colDefaultConf = {
  'newSpread': NEW_CARDS_DISTRIBUTE,
  'collapseTime': 1200000,
};

/// デフォルトのデッキ設定
final Map<String, dynamic> deckDefaultConf = {
  'new': {
    'delays': [1, 10], // 学習カードのステップ // 本番用
    // 'delays': [1, 1], // 学習カードのステップ // テスト用
    'ints': [1, 4], // 学習カードの間隔
    'initialFactor': STARTING_FACTOR, // EasyFactorの初期値
    'perDay': 20, // 1日の新規カードの最大枚数
  },
  'lapse': {
    'delays': [10],
    'mult': 0,
    'minInt': 1,
    'leechFails': 8,
  },
  'rev': {
    'perDay': 200,
    'ease4': 1.3,
    'ivlFct': 1,
    'maxIvl': 36500,
    'hardFactor': 1.2,
  },
};

/// コレクションクラス
class Collection {
  int crt;
  Map<String, Deck> decks;
  Map<String, dynamic> colConf;
  Map<String, dynamic> deckConf;
  late Scheduler sched;
  int newCardModulus = 0;

  Collection({int? id})
      : crt = clock.now().millisecondsSinceEpoch,
        decks = {},
        colConf = colDefaultConf,
        deckConf = deckDefaultConf {
    sched = Scheduler(this);
  }

  void addDeck(String deckName) {
    decks[deckName] = Deck(deckName);
  }

  void addCardToDeck(String deckName, Card card) {
    if (decks.containsKey(deckName)) {
      decks[deckName]!.addCard(card);
    } else {
      throw ArgumentError('デッキ $deckName が存在しません');
    }
  }

  static int _getStartOfDay() {
    DateTime now = clock.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    return startOfDay.millisecondsSinceEpoch ~/ 1000;
  }
}

/// デッキクラス
class Deck {
  String name;
  List<Card> cards;

  Deck(this.name) : cards = [];

  void addCard(Card card) {
    cards.add(card);
  }
}

/// 単語クラス
class Word {
  int id;
  String word;
  String? pronunciation; // オプショナルなプロパティ
  String mainMeaning;
  String? subMeaning; // オプショナルなプロパティ
  String sentence;
  String sentenceJp;
  String wordVoice; // 音声ファイルのURL
  String sentenceVoice; // 音声ファイルのURL

  Word({
    required this.id,
    required this.word,
    this.pronunciation, // オプショナル
    required this.mainMeaning,
    this.subMeaning, // オプショナル
    required this.sentence,
    required this.sentenceJp,
    required this.wordVoice,
    required this.sentenceVoice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'pronunciation': pronunciation,
      'main_meaning': mainMeaning,
      'sub_meaning': subMeaning,
      'sentence': sentence,
      'sentence_jp': sentenceJp,
      'word_voice': wordVoice,
      'sentence_voice': sentenceVoice,
    };
  }

  static Word fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      word: map['word'],
      pronunciation: map['pronunciation'],
      mainMeaning: map['main_meaning'],
      subMeaning: map['sub_meaning'],
      sentence: map['sentence'],
      sentenceJp: map['sentence_jp'],
      wordVoice: map['word_voice'],
      sentenceVoice: map['sentence_voice'],
    );
  }
}

/// カードクラス
class Card {
  int id;
  Word word;
  int due;
  int crt;
  int type;
  int queue;
  int ivl;
  int factor;
  int reps;
  int lapses;
  int left;

  Card(this.word, {int? id})
      : id = id ?? _generateUniqueId(),
        due = word.id,
        crt = _intTime(),
        type = 0,
        queue = 0,
        ivl = 0,
        factor = 0,
        reps = 0,
        lapses = 0,
        left = 0;

  static int _generateUniqueId() {
    int t = _intTimeMs();
    while (_intTimeMs() == t) {
      sleep(const Duration(milliseconds: 1));
    }
    return t;
  }

  static int _intTimeMs() {
    return clock.now().millisecondsSinceEpoch;
  }

  static int _intTime() {
    return clock.now().millisecondsSinceEpoch ~/ 1000;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': word.id,
      'due': due,
      'crt': crt,
      'type': type,
      'queue': queue,
      'ivl': ivl,
      'factor': factor,
      'reps': reps,
      'lapses': lapses,
      'left': left,
    };
  }

  static Card fromMap(Map<String, dynamic> map, Word word) {
    return Card(
      word,
      id: map['id'],
    )
      ..due = map['due']
      ..crt = map['crt']
      ..type = map['type']
      ..queue = map['queue']
      ..ivl = map['ivl']
      ..factor = map['factor']
      ..reps = map['reps']
      ..lapses = map['lapses']
      ..left = map['left'];
  }
}

class Scheduler {
  Collection col;
  int queueLimit;
  int reportLimit;
  int reps;
  int? today;
  int _lrnCutoff;
  int todayNewCardsCount = 0; // 1日に消化した新規カードの枚数 この変数は必要なさそう
  List<Card> lrnQueue = [];
  List<Card> revQueue = []; // DBで管理する
  List<Card> newQueue = []; // DBで管理する

  Scheduler(this.col)
      : queueLimit = 50,
        reportLimit = 1000,
        reps = 0,
        _lrnCutoff = 0 {
    newQueue = []; // ほんとはnewQueueにDBに保存した配列を入れる
    revQueue = []; // ほんとはrevfQueueにDBに保存した配列を入れる
  }

  Future<void> initializeScheduler() async {
    await _loadTodayNewCardsCount(); // 起動時に前回の新規カード消化数を読み込む
    _checkDay();
    print('日付: $today');
    print('1日の新規カード消化数: $todayNewCardsCount');
  }

  int get newQueueCount => newQueue.length;
  int get learningQueueCount => lrnQueue.length; //使っていないっぽい
  int get reviewQueueCount => revQueue.length;

  // カードの取得
// カードの取得
  Future<Card?> getCard() async {
    Card? card = await _getCard(); // 非同期メソッドの結果を待つ
    if (card != null) {
      print('Retrieved card ID: ${card.id}');
      reps += 1;
    } else {
      print('No card retrieved');
    }
    return card;
  }

  // 1日1回のキューリセット
  void reset() {
    _resetLrn();
    _resetRev();
    _resetNew();
    todayNewCardsCount = 0; // 今日消化した新規カードの枚数をリセット
    _saveTodayNewCardsCount(); // リセット後のカウントを保存
  }

  // カードへの回答
  void answerCard(Card card, int ease) {
    assert(ease >= 1 && ease <= 4);
    assert(card.queue >= 0 && card.queue <= 4);

    card.reps += 1;
    _removeCardFromQueue(card);
    _checkDay();

    if (card.queue == 0) {
      todayNewCardsCount += 1; //不要
      _saveTodayNewCardsCount(); // 新規カードの消化数を保存 //不要
      print('今日の新規カード消化数: $todayNewCardsCount');
      // 新規キューから来た場合、学習キューへ移動
      card.queue = 1;
      card.type = 1;
      // 卒業までのリピート数を初期化
      // card.left = _startingLeft(card);
    }

    if (card.queue == 1 || card.queue == 3) {
      _answerLrnCard(card, ease);
    } else if (card.queue == 2) {
      _answerRevCard(card, ease);
    } else {
      assert(false);
    }
  }

  void _removeCardFromQueue(Card card) {
    if (card.queue == 0) {
      newQueue.remove(card);
    } else if (card.queue == 1) {
      lrnQueue.remove(card);
    } else if (card.queue == 2) {
      revQueue.remove(card);
    }
  }

  // 日付が変わったかどうかを確認し、リセットする
  DateTime? lastCheck; // 最後にcheckDayを発動した日付

  Future<void> _checkDay() async {
    final dbHelper = DatabaseHelper.instance; // インスタンスを取得
    DateTime today = calculateCustomToday(); // 4時に日付が変わるTodayを取得
    await _loadLastCheckDate(); // SharedPreferencesからlastCheckを読み込む

    print('Current date: $today');
    print('Last check date: $lastCheck');

    if (lastCheck == null) {
      print('First time check or date not found, setting lastCheck to today.');
      lastCheck = today;
      await _saveLastCheckDate(lastCheck!);
    } else if (!isSameDay(lastCheck!, today)) {
      // 日付が異なる場合、リセット処理を実行
      await _fillNew(dbHelper);
      print('fillNewを実行します。');

      await _fillRev(dbHelper);
      print('fillRevを実行します。');

      lastCheck = today;
      await _saveLastCheckDate(lastCheck!);
    } else {
      print('日付が同じですが、念のためキューを更新します。');
      await _fillNew(dbHelper);
      await _fillRev(dbHelper);
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime calculateCustomToday() {
    DateTime now = DateTime.now();
    DateTime customToday;

    if (now.hour < 4) {
      customToday = DateTime(now.year, now.month, now.day - 1); // 前日扱い
    } else {
      customToday = DateTime(now.year, now.month, now.day); // 当日扱い
    }

    print('Custom Today Date: $customToday');
    return customToday;
  }

  Future<void> _saveLastCheckDate(DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCheck', date.toIso8601String());
    print('Saved last check date: ${date.toIso8601String()}');
  }

  Future<void> _loadLastCheckDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastCheckString = prefs.getString('lastCheck');
    if (lastCheckString != null) {
      lastCheck = DateTime.parse(lastCheckString);
      print('Loaded last check date: $lastCheck');
    } else {
      print('No last check date found, setting to null');
      lastCheck = null;
    }
  }

  int _daysSinceCreation() {
    // コレクションが作成された時間を取得
    final startDate = DateTime.fromMillisecondsSinceEpoch(col.crt * 1000);

    // 現在の時間と作成時間の差を日数として計算
    final currentTime = clock.now().millisecondsSinceEpoch ~/ 1000;
    final difference = currentTime - startDate.millisecondsSinceEpoch ~/ 1000;

    // 1日（86400秒）で割って日数を返す
    return difference ~/ 86400;
  }

  void _resetLrn() {
    // 学習キューをリセットする
    _updateLrnCutoff(force: true);
    lrnQueue = [];
  }

  bool _updateLrnCutoff({required bool force}) {
    final nextCutoff = clock.now().millisecondsSinceEpoch +
        (col.colConf['collapseTime'] as int);
    if (nextCutoff - _lrnCutoff > 60 || force) {
      _lrnCutoff = nextCutoff;
      return true;
    }
    return false;
  }

  void _resetRev() {
    // 復習キューをリセットする
    revQueue = [];
  }

  void _resetNew() {
    // 新規キューをリセットする
    newQueue = [];
    _updateNewCardRatio();
  }

  void _updateNewCardRatio() {
    // 新規カードの表示比率を更新する
    if (col.colConf['newSpread'] == NEW_CARDS_DISTRIBUTE) {
      if (newQueue.isNotEmpty) {
        final newCount = newQueue.length;
        final revCount = revQueue.length;
        final newCardModulus = ((newCount + revCount) ~/ newCount);
        if (revCount > 0) {
          col.newCardModulus = max(2, newCardModulus);
        } else {
          col.newCardModulus = 0;
        }
      }
    } else {
      col.newCardModulus = 0;
    }
  }

  // 新しいカードを表示する時間かどうかを判断する
  bool _timeForNewCard() {
    if (newQueue.isEmpty) {
      return false;
    }
    if (col.colConf['newSpread'] == NEW_CARDS_LAST) {
      return false;
    } else if (col.colConf['newSpread'] == NEW_CARDS_FIRST) {
      return true;
    } else if (col.newCardModulus != 0) {
      return reps != 0 && reps % col.newCardModulus == 0;
    }
    return false;
  }

  Future<Card?> _getCard() async {
    Card? card;

    // 学習カードの期限が来ているか？
    card = _getLrnCard();
    if (card != null) {
      return card;
    }

    // 新しいカードを優先するか、新しいカードの時間か？
    card = await _getNewCard(); // ここで新規カードを強制的に確認
    if (card != null) {
      print('New card retrieved: ${card.word.word}');
      return card;
    }

    // レビューするカードの期限が来ているか？
    card = _getRevCard();
    if (card != null) {
      return card;
    }

    print('No card retrieved');
    return null;
  }

  Future<Card?> _getNewCard() async {
    if (newQueue.isNotEmpty) {
      final card = newQueue.removeLast(); // キューから削除してカードを返す
      print('Retrieved new card: ${card.word.word}');
      return card;
    } else {
      print('No new card found');
    }
    return null; // newQueueが空の場合はnullを返す
  }

  Card? _getLrnCard({bool collapse = false}) {
    if (collapse) {
      // collapseがtrueの場合のみ、collapseTime以内のカードを考慮
      _maybeResetLrn(force: true);
    } else {
      // collapseがfalseの場合、現在の時間よりdueが早いカードのみ取得
      _maybeResetLrn(force: false);
    }
    if (_fillLrn(collapse: collapse)) {
      return lrnQueue.last; // キューから削除せず最後のカードを返す
    }
    return null;
  }

  void _maybeResetLrn({required bool force}) {
    if (_updateLrnCutoff(force: force)) {
      _resetLrn();
    }
  }

  bool _fillLrn({bool collapse = false}) {
    if (lrnQueue.isNotEmpty) {
      return true;
    }
    final currentTime = clock.now().millisecondsSinceEpoch;
    final cutoff = currentTime + (col.colConf['collapseTime'] as int);
    lrnQueue = col.decks.values
        .expand((deck) => deck.cards.where((card) =>
            card.type == 1 &&
            card.type == 3 &&
            (collapse ? card.due < cutoff : card.due < currentTime)))
        .toList();
    print('学習キューのカード枚数 : ${lrnQueue.length}');
    lrnQueue.sort((a, b) => a.due.compareTo(b.due));
    lrnQueue = lrnQueue.take(reportLimit).toList();
    return lrnQueue.isNotEmpty;
  }

  // FIXME: _refreshNewQueueとかに命名を変える
  Future<void> _fillNew(DatabaseHelper dbHelper) async {
    // 既存のnewQueueをクリア
    await dbHelper.clearQueue(0); // 0 = newQueue

    // すべての新規カードを取得し、dueが古い順にソート
    newQueue = col.decks.values
        .expand((deck) => deck.cards.where((card) => card.type == 0))
        .toList();
    newQueue.sort((a, b) => a.due.compareTo(b.due)); // 古い順にソート

    // 古いカード20枚を選択
    List<Card> newSelectedQueue = newQueue.take(20).toList();

    // 新しいnewQueueを挿入し、データベースのQueueテーブルを更新
    for (var card in newSelectedQueue) {
      newQueue.add(card); // newQueueに追加
      await dbHelper.insertCardToQueue(card.id, 0); // 0 = newQueue
    }
    print('New Queue after selection: ${newQueue.length}');
  }

//いらない疑惑あるなカウント数えるやつ
  void _saveTodayNewCardsCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('todayNewCardsCount', todayNewCardsCount);
    print('今日の新規カード消化数を保存しました: $todayNewCardsCount');
  }

  Future<void> _loadTodayNewCardsCount() async {
    final prefs = await SharedPreferences.getInstance();
    print('今日の新規カード消化数を読み込みます');
    todayNewCardsCount = prefs.getInt('todayNewCardsCount') ?? 0;
    print('今日の新規カード消化数を読み込みました: $todayNewCardsCount');
  }

  Card? _getRevCard() {
    if (revQueue.isNotEmpty) {
      return revQueue.last; // キューから削除せず最後のカードを返す
    }
    return null;
  }

  Future<void> _fillRev(DatabaseHelper dbHelper) async {
    // データベース内の旧revQueueを削除
    await dbHelper.clearQueue(2); // 2 = revQueueをクリア

    if (revQueue.isNotEmpty) {
      return;
    }

    final limit = min(queueLimit, col.deckConf['rev']['perDay'] as int);

    // 今日の終了時刻を取得
    final now = clock.now();
    final todayEnd = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    // 今日とそれ以前の due を持つカードを取得
    revQueue = col.decks.values
        .expand((deck) =>
            deck.cards.where((card) => card.queue == 2 && card.due <= todayEnd))
        .toList();
    revQueue.sort((a, b) => a.due.compareTo(b.due));
    revQueue = revQueue.take(limit).toList();

    // 新しいrevQueueを挿入し、データベースのQueueテーブルを更新
    for (var card in revQueue) {
      await dbHelper.insertCardToQueue(card.id, 2); // 2 = revQueue
    }

    if (revQueue.isNotEmpty) {
      final rand = Random(todayEnd);
      revQueue.shuffle(rand);
    }
    print('review Queue after selection: ${revQueue.length}');
  }

  void _answerLrnCard(Card card, int ease) {
    var conf = _lrnConf(card);

    // 即時卒業？
    if (ease == 4) {
      _rescheduleAsRev(card, conf, true);
    }
    // 次のステップ？
    else if (ease == 3) {
      // 卒業時期？
      if ((card.left % 1000) - 1 <= 0) {
        _rescheduleAsRev(card, conf, false);
      } else {
        _moveToNextStep(card, conf);
      }
    } else if (ease == 2) {
      _repeatStep(card, conf);
    } else {
      // 最初のステップに戻る
      _moveToFirstStep(card, conf);
    }
  }

  void _updateRevIvlOnFail(Card card, Map<String, dynamic> conf) {
    card.ivl = _lapseIvl(card, conf);
  }

  void _moveToFirstStep(Card card, Map<String, dynamic> conf) {
    // card.left = _startingLeft(card);

    // 再学習カード？
    if (card.type == 3) {
      _updateRevIvlOnFail(card, conf);
    }

    _rescheduleLrnCard(card, conf);
  }

  void _moveToNextStep(Card card, Map<String, dynamic> conf) {
    // 実際の残り回数を減少させ、今日の残り回数を再計算
    int left = (card.left % 1000) - 1;
    // card.left = _leftToday(conf['delays'], left) * 1000 + left;

    _rescheduleLrnCard(card, conf);
  }

  void _repeatStep(Card card, Map<String, dynamic> conf) {
    int delay = _delayForRepeatingGrade(conf, card.left);
    _rescheduleLrnCard(card, conf, delay: delay);
  }

  void _rescheduleLrnCard(Card card, Map<String, dynamic> conf, {int? delay}) {
    // 現在のステップの通常の遅延？
    delay ??= _delayForGrade(conf, card.left);

    card.due = clock.now().millisecondsSinceEpoch + delay;
    card.queue = 1;
  }

  // このメソッドがlrncardのdelayを設定している
  int _delayForGrade(Map<String, dynamic> conf, int left) {
    left = left % 1000;
    int index = conf['delays'].length - left;
    if (index < 0) {
      index = 0; // インデックスが負の場合、0に設定
    } else if (index >= conf['delays'].length) {
      index = conf['delays'].length - 1; // インデックスが範囲を超える場合、最大インデックスに設定
    }
    int delay = conf['delays'][index];
    return delay * 60 * 1000;
  }

  int _delayForRepeatingGrade(Map<String, dynamic> conf, int left) {
    // 最後と次の間の中間
    int delay1 = _delayForGrade(conf, left);
    int delay2 = _delayForGrade(conf, left - 1);
    return ((delay1 + max(delay1, delay2)) ~/ 2);
  }

  Map<String, dynamic> _lrnConf(Card card) {
    if (card.type == 2 || card.type == 3) {
      return col.deckConf["lapse"];
    } else {
      return col.deckConf["new"];
    }
  }

  void _rescheduleAsRev(Card card, Map<String, dynamic> conf, bool early) {
    bool lapse = card.type == 2 || card.type == 3;

    if (lapse) {
      _rescheduleGraduatingLapse(card);
    } else {
      _rescheduleNew(card, conf, early);
    }
  }

  void _rescheduleGraduatingLapse(Card card) {
    card.due =
        clock.now().millisecondsSinceEpoch + card.ivl * 24 * 60 * 60 * 1000;
    card.queue = 2;
    card.type = 2;
  }

  // int _startingLeft(Card card) {
  //   var conf = _lrnConf(card);
  //   int tot = conf['delays'].length; // 2
  //   int tod = _leftToday(conf['delays'], tot);
  //   return tot + tod * 1000;
  // }

  // lrn1かlrn2かを判断してそう こんなに複雑にしなくても良い！
  /*int _leftToday(List<int> delays, int left, {int? now}) {
    // 今日のカットオフまでに完了できるステップ数
    now ??= clock.now().millisecondsSinceEpoch ~/ 1000;
    delays = delays.sublist(delays.length - left);
    int ok = 0;
    for (int i = 0; i < delays.length; i++) {
      now = now! + delays[i] * 60;
      if (now > _dayCutoff) {
        break;
      }
      ok = i;
    }
    return ok + 1;
  }*/

  int _graduatingIvl(Card card, Map<String, dynamic> conf, bool early) {
    if (card.type == 2 || card.type == 3) {
      return card.ivl;
    }
    if (!early) {
      // 卒業
      return conf['ints'][0];
    } else {
      // 早期移動
      return conf['ints'][1];
    }
  }

  void _rescheduleNew(Card card, Map<String, dynamic> conf, bool early) {
    // カードが初めて卒業するときの復習感覚スケジュール
    card.ivl = _graduatingIvl(card, conf, early);
    card.due = clock.now().millisecondsSinceEpoch +
        card.ivl * 24 * 60 * 60 * 1000; //本番用
    // card.due =
    //     clock.now().millisecondsSinceEpoch + 1 * 60 * 1000; //テスト用で1分後に復習
    card.factor = conf['initialFactor'];
    card.type = card.queue = 2;
  }

  void _answerRevCard(Card card, int ease) {
    if (ease == 1) {
      _rescheduleLapse(card);
    } else {
      _rescheduleRev(card, ease);
    }
  }

  void _rescheduleLapse(Card card) {
    var conf = col.deckConf["lapse"];

    card.lapses += 1;
    card.factor = max(1300, card.factor - 200);

    bool suspended = _checkLeech(card, conf);

    if (!suspended) {
      card.type = 3;
      _moveToFirstStep(card, conf);
    } else {
      _updateRevIvlOnFail(card, conf);
    }
  }

  void _rescheduleRev(Card card, int ease) {
    _updateRevIvl(card, ease);

    card.factor = max(1300, card.factor + [-150, 0, 150][ease - 2]);
    card.due =
        clock.now().millisecondsSinceEpoch + card.ivl * 24 * 60 * 60 * 1000;
  }

  int _nextRevIvl(Card card, int ease) {
    int delay = _daysLate(card);
    var conf = col.deckConf["rev"];
    double fct = card.factor / 1000;
    double hardFactor = conf["hardFactor"];
    int hardMin = (hardFactor > 1) ? card.ivl : 0;
    int ivl2 = _constrainedIvl((card.ivl * hardFactor).toInt(), conf, hardMin);
    if (ease == 2) return ivl2;

    int ivl3 =
        _constrainedIvl(((card.ivl + delay ~/ 2) * fct).toInt(), conf, ivl2);
    if (ease == 3) return ivl3;

    int ivl4 = _constrainedIvl(
        ((card.ivl + delay) * fct * conf["ease4"]).toInt(), conf, ivl3);
    return ivl4;
  }

  // このメソッドでバカでかいivlが返ってくるときがある
  int _constrainedIvl(int ivl, Map<String, dynamic> conf, int prev) {
    ivl = (ivl * conf["ivlFct"]).toInt();
    ivl = max(ivl, max(prev + 1, 1));
    ivl = min(ivl, conf["maxIvl"]);
    return ivl;
  }

  // ここでの設定がどうかしている
  int _daysLate(Card card) {
    return max(0, today! - card.due); //dueの値がおかしいときがある
  }

  void _updateRevIvl(Card card, int ease) {
    card.ivl = _nextRevIvl(card, ease);
  }

  bool _checkLeech(Card card, Map<String, dynamic> conf) {
    int? lf = conf["leechFails"];
    if (lf == null) return false;

    if (card.lapses >= lf) {
      card.queue = -1;
      return true;
    }
    return false;
  }

  int _lapseIvl(Card card, Map<String, dynamic> conf) {
    int ivl = max(1, max(conf['minInt'], (card.ivl * conf['mult']).toInt()));
    return ivl;
  }
}

// void main() {
//   try {
//     // コレクションの作成とデッキの追加
//     Collection collection = Collection();
//     collection.addDeck('Japanese Vocabulary');

//     // 単語の作成とデッキへの追加
//     Word word1 = Word(
//       id: intId(),
//       word: 'example',
//       mainMeaning: '例',
//       subMeaning: '例え',
//       sentence: 'This is an example sentence.',
//       sentenceJp: 'これは例文です。',
//     );
//     Word word2 = Word(
//       id: intId(),
//       word: 'test',
//       mainMeaning: 'テスト',
//       subMeaning: '試験',
//       sentence: 'This is a test sentence.',
//       sentenceJp: 'これはテスト文です。',
//     );

//     Card card1 = Card(word1);
//     Card card2 = Card(word2);

//     collection.addCardToDeck('Japanese Vocabulary', card1);
//     collection.addCardToDeck('Japanese Vocabulary', card2);

//     print('Collection created at: ${collection.crt}');
//     print('Decks: ${collection.decks.keys}');
//     print(
//         'Cards in "Japanese Vocabulary" deck: ${collection.decks['Japanese Vocabulary']!.cards.length}');

//     // Schedulerのインスタンスを取得
//     Scheduler scheduler = collection.sched;

//     // カードを取得して確認
//     Card? card = scheduler.getCard();
//     if (card != null) {
//       print('Retrieved card ID: ${card.id}');
//       // カードに応答
//       scheduler.answerCard(card, 3);
//     } else {
//       print('No card to review.');
//     }

//     // カードの追加と再度の取得確認
//     Word word3 = Word(
//       id: intId(),
//       word: 'study',
//       mainMeaning: '勉強',
//       subMeaning: '学習',
//       sentence: 'I study every day.',
//       sentenceJp: '私は毎日勉強します。',
//     );
//     Card card3 = Card(word3);
//     collection.addCardToDeck('Japanese Vocabulary', card3);

//     card = scheduler.getCard();
//     if (card != null) {
//       print('Retrieved card ID: ${card.id}');
//       // カードに応答
//       scheduler.answerCard(card, 2);
//     } else {
//       print('No card to review.');
//     }

//     // デイリーリセットの確認
//     scheduler.reset();
//     print('Scheduler reset. Reps: ${scheduler.reps}');

//     // カードの取得と応答のテスト
//     void testCardRetrievalAndAnswer() {
//       Card? card = collection.sched.getCard();
//       if (card != null) {
//         print('Retrieved card ID: ${card.id}');
//         collection.sched.answerCard(card, 3); // ease 3 for the first card
//       }

//       card = collection.sched.getCard();
//       if (card != null) {
//         print('Retrieved card ID: ${card.id}');
//         collection.sched.answerCard(card, 4); // ease 4 for the second card
//       }

//       card = collection.sched.getCard();
//       if (card != null) {
//         print('Retrieved card ID: ${card.id}');
//         collection.sched.answerCard(card, 2); // ease 2 for the third card
//       }

//       print('Scheduler reps: ${collection.sched.reps}');
//     }

//     // 日付をまたいでのリセットのテスト
//     void testDayRollover() {
//       // 今日の終わりの時間を設定してテスト
//       collection.sched._dayCutoff =
//           clock.now().millisecondsSinceEpoch + 1000; // 1秒後にリセット
//       Future.delayed(Duration(seconds: 2), () {
//         collection.sched.getCard(); // リセットをトリガー
//         print('Day rollover check. Reps after reset: ${collection.sched.reps}');
//       });
//     }

//     // 学習カードと復習カードの動作確認
//     void testLearningAndReviewCards() {
//       // 学習カードの取得と確認
//       Card? card = collection.sched.getCard();
//       if (card != null) {
//         print('Learning card ID: ${card.id}');
//         collection.sched.answerCard(card, 3); // ease 3 for learning card
//       }

//       // 復習カードの取得と確認
//       card = collection.sched.getCard();
//       if (card != null) {
//         print('Review card ID: ${card.id}');
//         collection.sched.answerCard(card, 2); // ease 2 for review card
//       }
//     }

//     // テスト実行
//     print('Starting new tests...');
//     testCardRetrievalAndAnswer();
//     testDayRollover();
//     testLearningAndReviewCards();
//   } catch (e, stackTrace) {
//     print('Error: $e');
//     print('StackTrace: $stackTrace');
//   }
// }
