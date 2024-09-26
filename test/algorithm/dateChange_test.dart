import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:kokotan/algorithm/srs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Scheduler Day Change Tests', () {
    late Collection collection;
    late Scheduler scheduler;
    late Clock fixedClock;

    setUp(() {
      // SharedPreferencesの初期化
      SharedPreferences.setMockInitialValues({});

      // 固定された時間を使ってシステム時間を制御
      fixedClock = Clock.fixed(DateTime(2024, 9, 18, 23, 59, 59).toUtc());

      // コレクションとスケジューラの初期化
      collection = Collection();
      scheduler = Scheduler(collection, clock: fixedClock);
    });

    test('日付が変わらない場合はリセットされない', () {
      // リセットを検証するために日付変更の処理をモック
      scheduler.dayCutoff =
          fixedClock.now().millisecondsSinceEpoch + 60000; // 1分後にカットオフ
      scheduler.checkDay();

      expect(scheduler.todayNewCardsCount, 0, reason: '新規カード数はリセットされない');
    });

    test('日付が変わった場合はリセットされる', () {
      // リセットを検証するために日付を翌日に変更
      final nextDayClock = Clock.fixed(DateTime(2024, 9, 19, 0, 1, 0).toUtc());
      scheduler = Scheduler(collection, clock: nextDayClock);

      scheduler.dayCutoff =
          nextDayClock.now().millisecondsSinceEpoch - 60000; // 日付超過
      scheduler.checkDay();

      expect(scheduler.todayNewCardsCount, 0, reason: '新規カード数がリセットされている');
    });

    test('リセット時に学習キューと復習キューがクリアされる', () {
      scheduler.lrnQueue.add(Card(Word(
        id: 1,
        word: 'example',
        mainMeaning: 'example meaning',
        sentence: 'This is an example sentence.',
        sentenceJp: 'これは例文です。',
        wordVoice: 'example_voice.mp3',
        sentenceVoice: 'example_sentence_voice.mp3',
      )));
      scheduler.revQueue.add(Card(Word(
        id: 2,
        word: 'review',
        mainMeaning: 'review meaning',
        sentence: 'This is a review sentence.',
        sentenceJp: 'これは復習文です。',
        wordVoice: 'review_voice.mp3',
        sentenceVoice: 'review_sentence_voice.mp3',
      )));

      // 日付変更をシミュレート
      final nextDayClock = Clock.fixed(DateTime(2024, 9, 19, 0, 1, 0).toUtc());
      scheduler = Scheduler(collection, clock: nextDayClock);
      scheduler.checkDay();

      expect(scheduler.lrnQueue.isEmpty, isTrue, reason: '学習キューはリセットされるべき');
      expect(scheduler.revQueue.isEmpty, isTrue, reason: '復習キューはリセットされるべき');
    });

    test('新規カードの消化数が保存される', () async {
      // 新規カードの消化数を更新
      scheduler.todayNewCardsCount = 5;
      await scheduler.saveTodayNewCardsCount();

      // 保存された値を確認
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('todayNewCardsCount');

      expect(savedCount, 5, reason: '新規カードの消化数が正しく保存される');
    });

    test('新規カードの消化数がリセット後に0に戻る', () async {
      // 新規カードの消化数を更新
      scheduler.todayNewCardsCount = 5;
      scheduler.saveTodayNewCardsCount();

      // 日付変更後、消化数がリセットされるか確認
      final nextDayClock = Clock.fixed(DateTime(2024, 9, 19, 0, 1, 0).toUtc());
      scheduler = Scheduler(collection, clock: nextDayClock);
      scheduler.checkDay();

      expect(scheduler.todayNewCardsCount, 0, reason: '新規カードの消化数はリセットされる');
    });
  });
}
