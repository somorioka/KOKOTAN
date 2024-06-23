import 'dart:math';

// 新規カードの表示順設定
const int NEW_CARDS_DISTRIBUTE = 0;
const int NEW_CARDS_LAST = 1;
const int NEW_CARDS_FIRST = 2;

// プロモーション時の初期ファクター
const int STARTING_FACTOR = 2500;

/// ユーティリティ関数
int intTime({int scale = 1}) {
  return DateTime.now().millisecondsSinceEpoch ~/ scale;
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
  'collapseTime': 1200,
};

/// デフォルトのデッキ設定
final Map<String, dynamic> deckDefaultConf = {
  'new': {
    'delays': [1, 10], // 学習カードのステップ
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
      : crt = DateTime.now().millisecondsSinceEpoch,
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
    DateTime now = DateTime.now();
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
  String mainMeaning;
  String subMeaning;
  String sentence;
  String sentenceJp;

  Word({
    required this.id,
    required this.word,
    required this.mainMeaning,
    required this.subMeaning,
    required this.sentence,
    required this.sentenceJp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'mainMeaning': mainMeaning,
      'subMeaning': subMeaning,
      'sentence': sentence,
      'sentenceJp': sentenceJp,
    };
  }
}

/// カードクラス
class Card {
  int id;
  int wordId;
  int due;
  int crt;
  int type;
  int queue;
  int ivl;
  int factor;
  int reps;
  int lapses;
  int left;

  Card(this.wordId, {int? id})
      : id = id ?? _generateUniqueId(),
        due = wordId,
        crt = _intTime(),
        type = 0,
        queue = 0,
        ivl = 0,
        factor = 0,
        reps = 0,
        lapses = 0,
        left = 0;

  static int _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000);
  }

  static int _intTime() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}

class Scheduler {
  Collection col;
  int queueLimit;
  int reportLimit;
  int reps;
  int? today;
  int _lrnCutoff;
  late int _dayCutoff;
  List<Card> _lrnQueue = [];
  List<Card> _revQueue = [];
  List<Card> _newQueue = [];

  Scheduler(this.col)
      : queueLimit = 50,
        reportLimit = 1000,
        reps = 0,
        _lrnCutoff = 0 {
    reset();
  }

  // カードの取得
  Card? getCard() {
    _checkDay();
    Card? card = _getCard();
    if (card != null) {
      reps += 1;
    }
    return card;
  }

  // 1日1回のキューリセット
  void reset() {
    _updateCutoff();
    _resetLrn();
    _resetRev();
    _resetNew();
  }

  // カードへの回答
  void answerCard(Card card, int ease) {
    assert(ease >= 1 && ease <= 4);
    assert(card.queue >= 0 && card.queue <= 4);

    card.reps += 1;

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

  // 日付が変わったかどうかを確認し、リセットする
  void _checkDay() {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    if (today == null || DateTime.now().millisecondsSinceEpoch > cutoff) {
      reset();
    }
  }

  // 日付のカットオフを更新する
  void _updateCutoff() {
    // コレクションが作成されてからの経過日数を計算
    today = _daysSinceCreation();
    // 日の終了時間を設定
    _dayCutoff = _calculateDayCutoff();
  }

  int _daysSinceCreation() {
    // コレクションが作成されてからの経過日数を返す
    final startDate = DateTime.fromMillisecondsSinceEpoch(col.crt);
    final currentDate = DateTime.now();
    return currentDate.difference(startDate).inDays;
  }

  int _calculateDayCutoff() {
    // 日の終了時間を返す
    final date = DateTime.now();
    final nextDay =
        DateTime(date.year, date.month, date.day).add(Duration(days: 1));
    return nextDay.millisecondsSinceEpoch;
  }

  void _resetLrn() {
    // 学習キューをリセットする
    _updateLrnCutoff(force: true);
    _lrnQueue = [];
  }

  bool _updateLrnCutoff({required bool force}) {
    final nextCutoff = DateTime.now().millisecondsSinceEpoch +
        (col.colConf['collapseTime'] as int);
    if (nextCutoff - _lrnCutoff > 60 || force) {
      _lrnCutoff = nextCutoff;
      return true;
    }
    return false;
  }

  void _resetRev() {
    // 復習キューをリセットする
    _revQueue = [];
  }

  void _resetNew() {
    // 新規キューをリセットする
    _newQueue = [];
    _updateNewCardRatio();
  }

  void _updateNewCardRatio() {
    // 新規カードの表示比率を更新する
    if (col.colConf['newSpread'] == NEW_CARDS_DISTRIBUTE) {
      if (_newQueue.isNotEmpty) {
        final newCount = _newQueue.length;
        final revCount = _revQueue.length;
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
    if (_newQueue.isEmpty) {
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
    Card? c = _getLrnCard();
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
    return _getLrnCard(collapse: true);
  }

  Card? _getLrnCard({bool collapse = false}) {
    _maybeResetLrn(force: collapse);
    if (_fillLrn()) {
      return _lrnQueue.removeLast();
    }
    return null;
  }

  void _maybeResetLrn({required bool force}) {
    if (_updateLrnCutoff(force: force)) {
      _resetLrn();
    }
  }

  bool _fillLrn() {
    if (_lrnQueue.isNotEmpty) {
      return true;
    }
    final cutoff = DateTime.now().millisecondsSinceEpoch +
        col.colConf['collapseTime'] as int;
    _lrnQueue = col.decks.values
        .expand((deck) =>
            deck.cards.where((card) => card.queue == 1 && card.due < cutoff))
        .toList();
    _lrnQueue.sort((a, b) => a.id.compareTo(b.id));
    _lrnQueue = _lrnQueue.take(reportLimit).toList();
    return _lrnQueue.isNotEmpty;
  }

  Card? _getNewCard() {
    if (_fillNew()) {
      return _newQueue.removeLast();
    }
    return null;
  }

  bool _fillNew() {
    if (_newQueue.isNotEmpty) {
      return true;
    }
    final limit = min(queueLimit, col.deckConf['new']['perDay'] as int);
    _newQueue = col.decks.values
        .expand((deck) => deck.cards.where((card) => card.queue == 0))
        .toList();
    _newQueue.sort((a, b) => a.due.compareTo(b.due));
    _newQueue = _newQueue.take(limit).toList();
    return _newQueue.isNotEmpty;
  }

  Card? _getRevCard() {
    if (_fillRev()) {
      return _revQueue.removeLast();
    }
    return null;
  }

  bool _fillRev() {
    if (_revQueue.isNotEmpty) {
      return true;
    }
    final limit = min(queueLimit, col.deckConf['rev']['perDay'] as int);
    _revQueue = col.decks.values
        .expand((deck) =>
            deck.cards.where((card) => card.queue == 2 && card.due <= today!))
        .toList();
    _revQueue.sort((a, b) => a.due.compareTo(b.due));
    _revQueue = _revQueue.take(limit).toList();

    if (_revQueue.isNotEmpty) {
      final rand = Random(today);
      _revQueue.shuffle(rand);
      return true;
    }
    return false;
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

    card.due = DateTime.now().millisecondsSinceEpoch + delay;
    card.queue = 1;
  }

  int _delayForGrade(Map<String, dynamic> conf, int left) {
    left = left % 1000;
    int index = conf['delays'].length - left;
    if (index < 0) {
      index = 0; // インデックスが負の場合、0に設定
    } else if (index >= conf['delays'].length) {
      index = conf['delays'].length - 1; // インデックスが範囲を超える場合、最大インデックスに設定
    }
    int delay = conf['delays'][index];
    return delay * 60;
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
    card.due = today! + card.ivl;
    card.queue = 2;
    card.type = 2;
  }

  int _startingLeft(Card card) {
    var conf = _lrnConf(card);
    int tot = conf['delays'].length;
    int tod = _leftToday(conf['delays'], tot);
    return tot + tod * 1000;
  }

  int _leftToday(List<int> delays, int left, {int? now}) {
    // 今日のカットオフまでに完了できるステップ数
    now ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
    // 新規カードを初めて卒業するために再スケジュール
    card.ivl = _graduatingIvl(card, conf, early);
    card.due = today! + card.ivl;
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
    card.due = today! + card.ivl;
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

  int _constrainedIvl(int ivl, Map<String, dynamic> conf, int prev) {
    ivl = (ivl * conf["ivlFct"]).toInt();
    ivl = max(ivl, max(prev + 1, 1));
    ivl = min(ivl, conf["maxIvl"]);
    return ivl;
  }

  int _daysLate(Card card) {
    return max(0, today! - card.due);
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

void main() {
  try {
    // コレクションの作成とデッキの追加
    Collection collection = Collection();
    collection.addDeck('Japanese Vocabulary');

    // 単語の作成とデッキへの追加
    Word word1 = Word(
      id: intId(),
      word: 'example',
      mainMeaning: '例',
      subMeaning: '例え',
      sentence: 'This is an example sentence.',
      sentenceJp: 'これは例文です。',
    );
    Word word2 = Word(
      id: intId(),
      word: 'test',
      mainMeaning: 'テスト',
      subMeaning: '試験',
      sentence: 'This is a test sentence.',
      sentenceJp: 'これはテスト文です。',
    );

    Card card1 = Card(word1.id);
    Card card2 = Card(word2.id);

    collection.addCardToDeck('Japanese Vocabulary', card1);
    collection.addCardToDeck('Japanese Vocabulary', card2);

    print('Collection created at: ${collection.crt}');
    print('Decks: ${collection.decks.keys}');
    print(
        'Cards in "Japanese Vocabulary" deck: ${collection.decks['Japanese Vocabulary']!.cards.length}');

    // Schedulerのインスタンスを取得
    Scheduler scheduler = collection.sched;

    // カードを取得して確認
    Card? card = scheduler.getCard();
    if (card != null) {
      print('Retrieved card ID: ${card.id}');
      // カードに応答
      scheduler.answerCard(card, 3);
    } else {
      print('No card to review.');
    }

    // カードの追加と再度の取得確認
    Word word3 = Word(
      id: intId(),
      word: 'study',
      mainMeaning: '勉強',
      subMeaning: '学習',
      sentence: 'I study every day.',
      sentenceJp: '私は毎日勉強します。',
    );
    Card card3 = Card(word3.id);
    collection.addCardToDeck('Japanese Vocabulary', card3);

    card = scheduler.getCard();
    if (card != null) {
      print('Retrieved card ID: ${card.id}');
      // カードに応答
      scheduler.answerCard(card, 2);
    } else {
      print('No card to review.');
    }

    // デイリーリセットの確認
    scheduler.reset();
    print('Scheduler reset. Reps: ${scheduler.reps}');

    // カードの取得と応答のテスト
    void testCardRetrievalAndAnswer() {
      Card? card = collection.sched.getCard();
      if (card != null) {
        print('Retrieved card ID: ${card.id}');
        collection.sched.answerCard(card, 3); // ease 3 for the first card
      }

      card = collection.sched.getCard();
      if (card != null) {
        print('Retrieved card ID: ${card.id}');
        collection.sched.answerCard(card, 4); // ease 4 for the second card
      }

      card = collection.sched.getCard();
      if (card != null) {
        print('Retrieved card ID: ${card.id}');
        collection.sched.answerCard(card, 2); // ease 2 for the third card
      }

      print('Scheduler reps: ${collection.sched.reps}');
    }

    // 日付をまたいでのリセットのテスト
    void testDayRollover() {
      // 今日の終わりの時間を設定してテスト
      collection.sched._dayCutoff =
          DateTime.now().millisecondsSinceEpoch + 1000; // 1秒後にリセット
      Future.delayed(Duration(seconds: 2), () {
        collection.sched.getCard(); // リセットをトリガー
        print('Day rollover check. Reps after reset: ${collection.sched.reps}');
      });
    }

    // 学習カードと復習カードの動作確認
    void testLearningAndReviewCards() {
      // 学習カードの取得と確認
      Card? card = collection.sched.getCard();
      if (card != null) {
        print('Learning card ID: ${card.id}');
        collection.sched.answerCard(card, 3); // ease 3 for learning card
      }

      // 復習カードの取得と確認
      card = collection.sched.getCard();
      if (card != null) {
        print('Review card ID: ${card.id}');
        collection.sched.answerCard(card, 2); // ease 2 for review card
      }
    }

    // テスト実行
    print('Starting new tests...');
    testCardRetrievalAndAnswer();
    testDayRollover();
    testLearningAndReviewCards();
  } catch (e, stackTrace) {
    print('Error: $e');
    print('StackTrace: $stackTrace');
  }
}
