import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:clock/clock.dart';

class TimeTestPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Hookを使って状態を管理する
    final currentTime = useState<DateTime>(clock.now());

    void setToNextDay7AM() {
      currentTime.value = DateTime(
        currentTime.value.year,
        currentTime.value.month,
        currentTime.value.day + 1,
        7,
      );
    }

    void advanceTimeByOneMinute() {
      currentTime.value = currentTime.value.add(Duration(minutes: 1));
    }

    void advanceTimeByTenMinutes() {
      currentTime.value = currentTime.value.add(Duration(minutes: 10));
    }

    void advanceTimeByOneHour() {
      currentTime.value = currentTime.value.add(Duration(hours: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Time Test Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Time: ${currentTime.value}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: setToNextDay7AM,
              child: Text('Set to Next Day 7:00 AM'),
            ),
            ElevatedButton(
              onPressed: advanceTimeByOneMinute,
              child: Text('Advance Time by 1 Minute'),
            ),
            ElevatedButton(
              onPressed: advanceTimeByTenMinutes,
              child: Text('Advance Time by 10 Minutes'),
            ),
            ElevatedButton(
              onPressed: advanceTimeByOneHour,
              child: Text('Advance Time by 1 Hour'),
            ),
          ],
        ),
      ),
    );
  }
}
