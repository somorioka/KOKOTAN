import 'package:flutter/material.dart';
import 'package:kokotan/pages/record_screen.dart';

class OtsukareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('お疲れ様！'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            '今日の分をやりきりました！\n明日も頑張ってね！',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 10),
          Image.asset('assets/images/otsukare1.png'),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) {
                  return RecordScreen();
                }));
              },
              child: const Text('記録をみる')),
        ],
      ),
    );
  }
}
