import 'package:clock/clock.dart';
import 'package:kokotan/algorithm/srs.dart';
import 'package:test/test.dart';

//成功
//srs.dartの「_」を一時的に削除して行なった。

void main() {
  group('Scheduler fillLrn tests', () {
    test('dueが過去のものが、ちゃんとlrnQueueに入るか', () {
      // テスト用のカードを作成
      Card card1 = Card(Word(
        id: 1,
        word: 'study_today',
        mainMeaning: '勉強',
        sentence: 'Study this today.',
        sentenceJp: 'これは今日勉強する。',
        wordVoice: '/wordVoice.mp3',
        sentenceVoice: '/sentenceVoice.mp3',
      ));
      card1.queue = 1;
      card1.due = clock.now().millisecondsSinceEpoch - 1000; // 現在時刻の少し前に設定

      Card card2 = Card(Word(
        id: 2,
        word: 'study_soon',
        mainMeaning: '勉強',
        sentence: 'Study this soon.',
        sentenceJp: 'これはすぐ勉強する。',
        wordVoice: '/wordVoice.mp3',
        sentenceVoice: '/sentenceVoice.mp3',
      ));
      card2.queue = 1;
      card2.due = clock.now().millisecondsSinceEpoch - 500; // 現在時刻の少し前に設定

      Card card3 = Card(Word(
        id: 3,
        word: 'study_later',
        mainMeaning: '勉強',
        sentence: 'Study this later.',
        sentenceJp: 'これは後で勉強する。',
        wordVoice: '/wordVoice.mp3',
        sentenceVoice: '/sentenceVoice.mp3',
      ));
      card3.queue = 1;
      card3.due = clock.now().millisecondsSinceEpoch - 200; // 現在時刻の少し前に設定

      // デッキにカードを追加
      Deck deck = Deck('Test Deck');
      deck.addCard(card1);
      deck.addCard(card2);
      deck.addCard(card3);

      // コレクションを作成してデッキを追加
      Collection collection = Collection();
      collection.addDeck('Test Deck');
      collection.decks['Test Deck'] = deck;

      // スケジューラを初期化
      Scheduler scheduler = collection.sched;

      // fillLrnをテスト
      expect(scheduler.fillLrn(), isTrue); // 正しく学習キューに追加されているか確認
      expect(scheduler.learningQueueCount, equals(3)); // 学習キューに3枚追加されているはず
    });

    test('未来のカードがcollapse trueで学習キューに入るかをテスト', () {
      // 1分後のカードを作成
      Card card1 = Card(Word(
        id: 1,
        word: 'study_1min_later',
        mainMeaning: '1分後に勉強する',
        sentence: 'Study this in 1 minute.',
        sentenceJp: 'これは1分後に勉強する。',
        wordVoice: '/wordVoice.mp3',
        sentenceVoice: '/sentenceVoice.mp3',
      ));
      card1.queue = 1;
      card1.due = clock.now().millisecondsSinceEpoch + 1 * 60 * 1000; // 1分後

      // 10分後のカードを作成
      Card card2 = Card(Word(
        id: 2,
        word: 'study_10min_later',
        mainMeaning: '10分後に勉強する',
        sentence: 'Study this in 10 minutes.',
        sentenceJp: 'これは10分後に勉強する。',
        wordVoice: '/wordVoice.mp3',
        sentenceVoice: '/sentenceVoice.mp3',
      ));
      card2.queue = 1;
      card2.due = clock.now().millisecondsSinceEpoch + 10 * 60 * 1000; // 10分後

      // コレクションとスケジューラをセットアップ
      Collection collection = Collection();
      collection.addDeck('Test Deck');

      // デッキにカードを追加
      collection.addCardToDeck('Test Deck', card1);
      collection.addCardToDeck('Test Deck', card2);

      // Schedulerのインスタンスを取得
      Scheduler scheduler = collection.sched;

      // collapseをtrueにして学習キューをテスト
      bool result = scheduler.fillLrn(collapse: true);

      // 結果の確認
      print('学習キューのカード枚数 : ${scheduler.learningQueueCount}');
      expect(scheduler.learningQueueCount, 2); // 学習キューに2枚カードが入ることを期待
    });
  });
}
