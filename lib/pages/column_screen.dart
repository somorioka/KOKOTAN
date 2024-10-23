import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ColumnScreen extends HookWidget {
  final List<Map<String, dynamic>> allContents = [
    {
      'name': '１リスニングを活用せよ！',
      'content': 'リスニングを活用することで、より効率的に学習できます。具体的な方法としては...',
      'icon': Icons.article,
      'section': '基本事項',
    },
    {
      'name': '２画像検索でイメージ記憶！',
      'content': '画像検索を使うことで、視覚的に情報を覚えやすくなります。具体的には...',
      'icon': Icons.book,
      'section': '基本事項',
    },
    {
      'name': '３英英辞典で真の意味を捉える',
      'content': '英英辞典を使うことで、言葉のニュアンスや真の意味を理解できます。たとえば...',
      'icon': Icons.web,
      'section': 'スキーマを育てるために',
    },
    {
      'name': '４英英辞典で真の意味を捉える',
      'content': '英英辞典を使うことで、言葉のニュアンスや真の意味を理解できます。たとえば...',
      'icon': Icons.web,
      'section': 'スキーマを育てるために',
    },
    {
      'name': '５画像検索でイメージ記憶！',
      'content': '画像検索を使うことで、視覚的に情報を覚えやすくなります。具体的には...',
      'icon': Icons.book,
      'section': 'スキーマを育てるために',
    },
    {
      'name': '６単語の語源を理解しよう',
      'content': '単語の語源を知ることで、語彙力がさらに向上します...',
      'icon': Icons.language,
      'section': 'その他',
    },
    {
      'name': '７自分の目標を明確にする',
      'content': '学習において目標設定は重要です。自分のゴールを定めることで...',
      'icon': Icons.flag,
      'section': 'その他',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedContent = useState<String?>(null);
    final selectedName = useState<String?>('お役立ちコラム');
    final selectedIndex = useState<int>(-1);

    void loadPage(int index) {
      if (index >= 0 && index < allContents.length) {
        selectedContent.value = allContents[index]['content']!;
        selectedName.value = allContents[index]['name']!;
        selectedIndex.value = index;
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(selectedName.value!),
        leading: selectedContent.value == null
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () {
                  selectedContent.value = null;
                  selectedName.value = 'お役立ちコラム';
                  selectedIndex.value = -1;
                },
              ),
      ),
      body: Stack(
        children: [
          if (selectedContent.value == null)
            ListView(
              children: [
                _buildSectionTitle('基本事項'),
                _buildContentList(
                    allContents
                        .where((item) => item['section'] == '基本事項')
                        .toList(),
                    loadPage),
                _buildSectionTitle('スキーマを育てるために'),
                _buildContentList(
                    allContents
                        .where((item) => item['section'] == 'スキーマを育てるために')
                        .toList(),
                    loadPage),
                _buildSectionTitle('その他'),
                _buildContentList(
                    allContents
                        .where((item) => item['section'] == 'その他')
                        .toList(),
                    loadPage),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Text(
                          selectedContent.value!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      if (selectedIndex.value > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              loadPage(selectedIndex.value - 1);
                            },
                            child: Text(
                              '◀︎ 前の記事   ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      if (selectedIndex.value < allContents.length - 1)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              loadPage(selectedIndex.value + 1);
                            },
                            child: Text(
                              '   次の記事 ▶︎',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 60, 177, 180),
                child: Icon(
                  contents[index]['icon'],
                  color: Colors.white,
                ),
              ),
              title: Text(
                contents[index]['name']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
}
