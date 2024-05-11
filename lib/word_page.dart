import 'package:flutter/material.dart';

class WordPage extends StatelessWidget {
  final int startIndex;
  final int endIndex;

  WordPage(this.startIndex, this.endIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Words: $startIndex - $endIndex'),
      ),
      body: Center(
        child: Text('Words from $startIndex to $endIndex'),
      ),
    );
  }
}