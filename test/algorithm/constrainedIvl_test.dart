import 'package:flutter_test/flutter_test.dart';
import 'package:kokotan/algorithm/srs.dart';
import 'dart:math';

//成功
//constrainedIvlのコメントで「ばかでかいivlが返ってくることがある」とあったのでやってみた。
//別のところに原因があるのか、もっと違う可能性をテストすべきなのか…


// テスト用にSchedulerクラスのメソッドをコピー
int _constrainedIvl(int ivl, Map<String, dynamic> conf, int prev) {
  ivl = (ivl * conf["ivlFct"]).toInt();
  ivl = max(ivl, max(prev + 1, 1));
  ivl = min(ivl, conf["maxIvl"]);
  return ivl;
}

void main() {

  group('constrainedIvl テスト', () {
    // メソッドの定義部分
    int _constrainedIvl(int ivl, Map<String, dynamic> conf, int prev) {
      ivl = (ivl * conf["ivlFct"]).toInt();
      ivl = max(ivl, max(prev + 1, 1));
      ivl = min(ivl, conf["maxIvl"]);
      return ivl;
    }

    test('通常のケース', () {
      final conf = {
        'ivlFct': 1.5,
        'maxIvl': 100,
      };
      final ivl = 50;
      final prev = 40;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 75); // 50 * 1.5 = 75
    });

    test('ivl が 0 の場合', () {
      final conf = {
        'ivlFct': 2.0,
        'maxIvl': 100,
      };
      final ivl = 0;
      final prev = 10;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 11); // max(0 * 2, max(10 + 1, 1)) = 11
    });

    test('prev が ivl より大きい場合', () {
      final conf = {
        'ivlFct': 2.0,
        'maxIvl': 100,
      };
      final ivl = 30;
      final prev = 35;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 60); // max(30 * 2, max(35 + 1, 1)) = 60
    });

    test('maxIvl の制約を超えた場合', () {
      final conf = {
        'ivlFct': 10.0,
        'maxIvl': 100,
      };
      final ivl = 15;
      final prev = 10;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 100); // min(15 * 10, 100) = 100
    });

    test('prev が負の数の場合', () {
      final conf = {
        'ivlFct': 2.0,
        'maxIvl': 100,
      };
      final ivl = 20;
      final prev = -5;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 40); // max(20 * 2, max(-5 + 1, 1)) = 40
    });

    test('ivlFct が 1 未満の場合', () {
      final conf = {
        'ivlFct': 0.5,
        'maxIvl': 100,
      };
      final ivl = 20;
      final prev = 15;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 16); // max(20 * 0.5, max(15 + 1, 1)) = 16
    });

    test('ivlFct が 0 の場合', () {
      final conf = {
        'ivlFct': 0.0,
        'maxIvl': 100,
      };
      final ivl = 20;
      final prev = 15;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 16); // max(20 * 0, max(15 + 1, 1)) = 16
    });

    test('maxIvl が ivl より小さい場合', () {
      final conf = {
        'ivlFct': 2.0,
        'maxIvl': 10,
      };
      final ivl = 20;
      final prev = 5;

      final result = _constrainedIvl(ivl, conf, prev);
      expect(result, 10); // min(20 * 2, 10) = 10
    });
  });
}


