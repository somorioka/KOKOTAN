import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
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

  // 新しいプロパティを追加
  String? englishDefinition; // 英英
  String? etymology; // 語源
  String? memo; // その他なんでもメモ
  String? imageUrl; // 画像URL

  Word({
    required this.id,
    required this.word,
    this.pronunciation,
    required this.mainMeaning,
    this.subMeaning,
    required this.sentence,
    required this.sentenceJp,
    required this.wordVoice,
    required this.sentenceVoice,
    this.englishDefinition, // 新しいプロパティ
    this.etymology, // 新しいプロパティ
    this.memo, // 新しいプロパティ
    this.imageUrl, // 新しいプロパティ
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
      'english_definition': englishDefinition, // 新しいプロパティ
      'etymology': etymology, // 新しいプロパティ
      'memo': memo, // 新しいプロパティ
      'image_url': imageUrl, // 新しいプロパティ
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
      englishDefinition: map['english_definition'], // 新しいプロパティ
      etymology: map['etymology'], // 新しいプロパティ
      memo: map['memo'], // 新しいプロパティ
      imageUrl: map['image_url'], // 新しいプロパティ
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
        due = 9727332272713, //dueの初期値をめっちゃ未来にした
        crt = _intTime(),
        type = 0,
        queue = 0,
        ivl = 0,
        factor = 0,
        reps = 0,
        lapses = 0,
        left = 0;

  // コピーコンストラクタを追加
  Card copy() {
    return Card(
      word, // Wordクラスが複雑であれば、これもコピーする必要があるかも
      id: id,
    )
      ..due = this.due
      ..crt = this.crt
      ..type = this.type
      ..queue = this.queue
      ..ivl = this.ivl
      ..factor = this.factor
      ..reps = this.reps
      ..lapses = this.lapses
      ..left = this.left;
  }

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
  int _dayCutoff = 0; // 初回起動時にもcheckDayを動かすため
  List<Card> lrnQueue = [];
  List<Card> revQueue = [];
  List<Card> newQueue = [];

  Scheduler(this.col)
      : queueLimit = 50,
        reportLimit = 1000,
        reps = 0,
        _lrnCutoff = 0 {
    _dayCutoff = 0;
  }

  Future<void> initializeScheduler(
      {required Function(Card) onDueUpdated}) async {
    await checkDay(onDueUpdated: onDueUpdated); // コールバックを渡す
  }

  int get newQueueCount => newQueue.length;
  int get learningQueueCount => lrnQueue.length;
  int get reviewQueueCount => revQueue.length;

  // カードの取得
  Future<Card?> getCard() async {
    await checkDay();
    Card? card = _getCard();
    if (card != null) {
      reps += 1;
    }
    return card;
  }

  // 1日1回のキューリセット
  Future<void> reset(Function(Card)? onDueUpdated) async {
    print('resetを実行しています');
    _updateCutoff();
    _resetLrn();
    _resetRev();
    _resetNew();

    await assignDueToNewCards(onDueUpdated); // コールバックを渡すか、nullなら無視

    fillNew();
    fillRev();
    print('resetが完了しました');
  }

  Future<void> assignDueToNewCards(Function(Card)? onDueUpdated) async {
    print('--- assignDueToNewCardsを実行しています ---');

    int perDayLimit = col.deckConf['new']['perDay'] as int;

    // すべてのデッキに対して処理を実行
    for (var deck in col.decks.values) {
      // queue == 0 のカード（新規カード）をすべて取得
      List<Card> newCards =
          deck.cards.where((card) => card.queue == 0).toList();

      // すべての新規カードのdueを初期値に戻す（例: -1を初期値とする場合）
      for (var card in newCards) {
        card.due = 9727332272713; // ここでdueを初期値にリセット
        if (onDueUpdated != null) {
          onDueUpdated(card); // コールバックがあれば呼び出す
        }
      }

      // 新規カードをソートして、一日の制限枚数に合わせて制限を適用
      if (newCards.isNotEmpty) {
        newCards.sort((a, b) => a.id.compareTo(b.id));
        List<Card> limitedCards = newCards.take(perDayLimit).toList();

        // 制限されたカードのdueを0に設定（今日の学習対象にする）
        for (var card in limitedCards) {
          card.due = 0; // 今日の対象カードはdueを0にする
          if (onDueUpdated != null) {
            onDueUpdated(card); // コールバックがある場合のみ実行
          }
        }
      }
    }

    print('--- assignDueToNewCardsが完了しました ---');
  }

  // カードへの回答
  void answerCard(Card card, int ease) {
    assert(ease >= 1 && ease <= 4);
    assert(card.queue >= 0 && card.queue <= 4);

    card.reps += 1;
    _removeCardFromQueue(card);

    if (card.queue == 0) {
      // 新規キューから来た場合、学習キューへ移動
      card.queue = 1;
      card.type = 1;
      // 卒業までのリピート数を初期化
      card.left = _startingLeft(card);
    }

    if (card.queue == 1 || card.queue == 3) {
      _answerLrnCard(card, ease);
    } else if (card.queue == 2) {
      _answerRevCard(card, ease);
    } else {
      assert(false);
    }
  }

  void removeCardFromQueue(Card card) {
    if (card.queue == 0) {
      newQueue.remove(card);
    } else if (card.queue == 1) {
      lrnQueue.remove(card);
    } else if (card.queue == 2) {
      revQueue.remove(card);
    }
  }

  // dayCutoffを保存するメソッド（秒単位のUNIXタイムスタンプ）
  Future<void> saveDayCutoff(int cutoffTimestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dayCutoff', cutoffTimestamp);
  }

// dayCutoffを取得するメソッド（秒単位のUNIXタイムスタンプ）
  Future<int?> getDayCutoff() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('dayCutoff');
  }

  // 日付が変わったかどうかを確認し、リセットする
  Future<void> _checkDay({Function(Card)? onDueUpdated}) async {
    print('checkDayを実行しています');

    int _dayCutoff = (await getDayCutoff()) ?? 0;
    final currentTime = clock.now().millisecondsSinceEpoch ~/ 1000; // 秒単位で取得

    if (currentTime > _dayCutoff) {
      await reset(onDueUpdated); // コールバックがある場合だけ渡す
    }

    print('checkDayを完了しました');
  }

  // 日付のカットオフを更新する
  void _updateCutoff() {
    // コレクションが作成されてからの経過日数を計算
    today = _daysSinceCreation();
    // 日の終了時間を設定
    _dayCutoff = _calculateDayCutoff();
    saveDayCutoff(_dayCutoff);
  }

  int _calculateDayCutoff() {
    // 今日の日付を取得し、時間を00:00:00にリセット
    final now = clock.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // 今日の現在時刻が00:00:00より遅い場合、次の日の00:00:00を計算
    final nextMidnight = todayMidnight.add(const Duration(days: 1));

    // 次の日の00:00:00をUNIXタイムスタンプ（秒単位）として返す
    return nextMidnight.millisecondsSinceEpoch ~/ 1000;
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
    updateNewCardRatio();
  }

  void updateNewCardRatio() {
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

  Card? _getCard() {
    // 次にレビューするカードを返す。カードがない場合はnullを返す。
    // 学習カードの期限が来ているか？
    Card? c = getLrnCard();
    if (c != null) {
      return c;
    }

    // 新しいカードを優先するか、新しいカードの時間か？
    if (_timeForNewCard()) {
      c = _getNewCard();
      if (c != null) {
        return c;
      }
    }

    // レビューするカードの期限が来ているか？
    c = _getRevCard();
    if (c != null) {
      return c;
    }

    // 新しいカードが残っているか？
    c = _getNewCard();
    if (c != null) {
      return c;
    }

    // collapseまたは終了
    c = getLrnCard(collapse: true);
    return c;
  }

  Card? getLrnCard({bool collapse = false}) {
    if (collapse) {
      // collapseがtrueの場合のみ、collapseTime以内のカードを考慮
      _maybeResetLrn(force: true);
    } else {
      // collapseがfalseの場合、現在の時間よりdueが早いカードのみ取得
      _maybeResetLrn(force: false);
    }
    if (fillLrn(collapse: collapse)) {
      return lrnQueue.last; // キューから削除せず最後のカードを返す
    }
    return null;
  }

  void _maybeResetLrn({required bool force}) {
    if (_updateLrnCutoff(force: force)) {
      _resetLrn();
    }
  }

  bool fillLrn({bool collapse = false}) {
    print('fillLrnを実行しています');

    if (lrnQueue.isNotEmpty) {
      return true;
    }
    final currentTime = clock.now().millisecondsSinceEpoch;
    final cutoff = currentTime + (col.colConf['collapseTime'] as int);
    lrnQueue = col.decks.values
        .expand((deck) => deck.cards.where((card) =>
            card.type == 1 && card.type == 3 &&
            (collapse ? card.due < cutoff : card.due < currentTime)))
        .toList();
    print('学習キューのカード枚数 : ${_lrnQueue.length}');
    _lrnQueue.sort((a, b) => a.due.compareTo(b.due));
    _lrnQueue = _lrnQueue.take(reportLimit).toList();
    print('fillLrnを完了しました');
    return lrnQueue.isNotEmpty;
  }

  Card? _getNewCard() {
    if (fillNew()) {
      return newQueue.last; // キューから削除せず最後のカードを返す
    }
    return null;
  }

  bool fillNew() {
    print('fillNewを実行しています');
    if (newQueue.isNotEmpty) {
      return true;
    }
    //dueが現在時刻以下、かつqueueが0
    newQueue = col.decks.values
        .expand((deck) =>
            deck.cards.where((card) => card.queue == 0 && card.due <= 1))
          .toList();
    newQueue.sort((a, b) => a.due.compareTo(b.due));

    if (newQueue.isNotEmpty) {
        return true;
    }
    print('fillNewが完了しました');
    return false;
  }

  Card? _getRevCard() {
    if (fillRev()) {
      return revQueue.last; // キューから削除せず最後のカードを返す
    }
    return null;
  }

  bool fillRev() {
    print('fillRevを実行しています');

    if (revQueue.isNotEmpty) {
      return true;
    }
    final limit = min(queueLimit, col.deckConf['rev']['perDay'] as int);

    // 今日の終了時刻を取得
    final now = clock.now();
    final todayEnd = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    revQueue = col.decks.values
        .expand((deck) => deck.cards.where((card) =>
            card.queue == 2 && card.due <= todayEnd)) // 今日の終了時刻までのカードを選択
        .toList();
    revQueue.sort((a, b) => a.due.compareTo(b.due));
    revQueue = revQueue.take(limit).toList();

    if (revQueue.isNotEmpty) {
      final rand = Random(today);
      revQueue.shuffle(rand);
      return true;
    }
    print('fillRevが完了しました');
    return false;
  }

  void fillAll() {
    print('fillAllを実行しています');

    fillNew();
    fillLrn();
    fillRev();
    print('fillAllが完了しました');
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
    card.left = _startingLeft(card);

    // 再学習カード？
    if (card.type == 3) {
      _updateRevIvlOnFail(card, conf);
    }

    _rescheduleLrnCard(card, conf);
  }

  void _moveToNextStep(Card card, Map<String, dynamic> conf) {
    // 実際の残り回数を減少させ、今日の残り回数を再計算
    int left = (card.left % 1000) - 1;
    card.left = _leftToday(conf['delays'], left) * 1000 + left;

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

  int _startingLeft(Card card) {
    var conf = _lrnConf(card);
    int tot = conf['delays'].length; // 2
    int tod = _leftToday(conf['delays'], tot);
    return tot + tod * 1000;
  }

  // lrn1かlrn2かを判断してそう こんなに複雑にしなくても良い！
  int _leftToday(List<int> delays, int left, {int? now}) {
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
  }

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

  int nextRevIvl(Card card, int ease) {
    int delay = daysLate(card); //ミリ秒
    int delayInDays = delay ~/ (24 * 60 * 60 * 1000); //ivlと計算するときは日数
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
    card.ivl = nextRevIvl(card, ease);
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

  // srs.dart 内に設定を受け取るメソッドを追加
  void updateDeckLimits({required int newLimit, required int reviewLimit}) {
    col.deckConf['new']['perDay'] = newLimit;
    col.deckConf['rev']['perDay'] = reviewLimit;
  }
}
