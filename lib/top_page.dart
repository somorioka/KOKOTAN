import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showDetails = false; // 詳細を表示するかどうかのフラグ
  Uint8List? _imageData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            showDetails = !showDetails;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 64.0, left: 25.0, bottom: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Practice',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    tooltip: 'Play sound',
                    onPressed: () {
                      // Play sound logic here
                    },
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: showDetails ? 1.0 : 0.0,
              duration: Duration(milliseconds: 0),
              child: Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Text('実践, 実行 ; (社会の) 慣習 ; 練習', style: TextStyle(fontSize: 20, color: Colors.black)),
                    Container(
                      decoration: BoxDecoration(
                        // 背景色を追加
                        color: Color.fromARGB(255, 249, 249, 208),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '実践, 実行 ; (社会の) 慣習 ; 練習',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'The manager decided to put his new ideas into practice.\n部長は自分の新しい考えを実行することに決めた。',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up),
                      tooltip: 'Play sound',
                      onPressed: () {
                        // Play sound logic here
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _searchImage("practice");
                            },
                            child: Text('画像検索'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchImage("practice");
                            },
                            child: Text('辞書'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchImage("practice");
                            },
                            child: Text('英英辞典'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60),
                    DropRegion(
                      onDropOver: (event) => DropOperation.move,
                      formats: Formats.standardFormats,
                      onPerformDrop: (event) async {
                        final item = event.session.items.first;
                        final reader = item.dataReader!;
                        if (reader.canProvide(Formats.jpeg)) {
                          reader.getFile(Formats.jpeg, (file) {
                            file.readAll().then((data) {
                              setState(() {
                                _imageData = data;
                              });
                            });
                          }, onError: (error) {
                            print('Error reading image: $error');
                          });
                        }
                      },
                      child: _imageData == null
                          ? Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Image.asset('assets/images/add-picture.png',
                                      width: 50, height: 50),
                                  Text('ここに画像をドロップ！',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            )
                          : Image.memory(_imageData!),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchImage(String keyword) async {
    final _url = Uri.parse('https://www.google.com/search?tbm=isch&q=$keyword');
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}
