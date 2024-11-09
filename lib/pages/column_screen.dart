import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kokotan/model/column_list.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // 追加

class ColumnScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedContent = useState<String?>(null);
    final selectedImageUrl = useState<String?>(null); // 選択された画像URL
    final selectedName = useState<String?>('お役立ちコラム');
    final selectedIndex = useState<int>(-1);

    void loadPage(int index) {
      if (index >= 0 && index < allContents.length) {
        selectedContent.value = allContents[index]['content']!;
        selectedImageUrl.value = allContents[index]['imageUrl']; // 画像URLを設定
        selectedName.value = allContents[index]['name']!;
        selectedIndex.value = index;
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false, // 左上の戻るボタンを非表示
        title: Text(selectedName.value!),
        leading: selectedContent.value == null
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () {
                  selectedContent.value = null;
                  selectedImageUrl.value = null;
                  selectedName.value = 'お役立ちコラム';
                  selectedIndex.value = -1;
                },
              ),
      ),
      body: selectedContent.value == null
          ? ListView(
              children: [
                _buildSectionTitle('ココタンとは'),
                _buildContentList(
                  allContents
                      .where((item) => item['section'] == 'ココタンとは')
                      .toList(),
                  loadPage,
                ),
                _buildSectionTitle('ココタンおすすめ活用法'),
                _buildContentList(
                  allContents
                      .where((item) => item['section'] == 'ココタンおすすめ活用法')
                      .toList(),
                  loadPage,
                ),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedImageUrl.value != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          selectedImageUrl.value!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              '画像を読み込めませんでした',
                              style: TextStyle(color: Colors.red),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    Text(
                      selectedContent.value!,
                      style: TextStyle(
                          fontFamily: 'ZenMaruGothic',
                          fontWeight: FontWeight.w400, // Bold
                          fontSize: 16,
                          color: Color(0xFF333333)),
                    ),
                    SizedBox(height: 16),
                    _buildNavigationButtons(selectedIndex.value, loadPage),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'ZenMaruGothic', // フォントファミリーを指定
          color: Color(0xFF333333), // 色の指定
        ),
      ),
    );
  }

  Widget _buildContentList(
      List<Map<String, dynamic>> contents, Function loadPage) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  contents[index]['icon'],
                  color: Color.fromARGB(255, 60, 177, 180),
                ),
              ),
              title: Text(
                contents[index]['name']!,
                style: TextStyle(
                    fontFamily: 'ZenMaruGothic',
                    fontWeight: FontWeight.w700, // Bold
                    fontSize: 17,
                    color: Color(0xFF333333)),
              ),
              onTap: () {
                loadPage(index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(int index, Function loadPage) {
    return Column(
      children: [
        if (index > 0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 60, 177, 180), // 背景色
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 30.0), // ボタンのサイズ調整
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 角丸の設定
                ),
                elevation: 6, // 浮き上がっているような影の深さ
              ),
              onPressed: () {
                loadPage(index - 1);
              },
              child: Text(
                '前の記事',
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // 太字
                  fontSize: 20,
                  color: Colors.white, // 白色の文字
                ),
              ),
            ),
          ),
        SizedBox(height: 10),
        if (index < allContents.length - 1)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 60, 177, 180), // 背景色
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 30.0), // ボタンのサイズ調整
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 角丸の設定
                ),
                elevation: 6, // 浮き上がっているような影の深さ
              ),
              onPressed: () {
                loadPage(index + 1);
              },
              child: Text(
                '次の記事',
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // 太字
                  fontSize: 20,
                  color: Colors.white, // 白色の文字
                ),
              ),
            ),
          ),
      ],
    );
  }
}
