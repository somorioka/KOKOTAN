import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // パッケージを追加
import 'package:share_plus/share_plus.dart';
import 'dart:io'; // 追加

class SettingsScreen extends StatelessWidget {
  // URLを開くメソッド
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 左上の戻るボタンを非表示

        title: Text('メニュー'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.share),
            title: Text('シェア'),
            onTap: () {
              Share.share('Check out this app: <アプリのURL>');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text('評価'),
            onTap: () {
              // AndroidとiOSで異なるURLを使用する
              final url = Platform.isAndroid
                  ? 'https://play.google.com/store/apps/details?id=<アプリのパッケージ名>'
                  : 'https://apps.apple.com/app/id<アプリのID>';
              _launchURL(url);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('ご意見'),
            onTap: () {
              _launchURL('https://kokomirai.jp/page-6687/');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.emoji_people),
            title: Text('１分で分かるここみらい'),
            onTap: () {
              _launchURL('https://kokomirai.jp/page-6355/');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.grid_view),
            title: Text('ここみらいの他のアプリ'),
            onTap: () {
              _launchURL('https://kokomirai.jp/page-6391/');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('ここみらいチャンネル(YouTube)'),
            onTap: () {
              _launchURL('https://www.youtube.com/@kokomirai');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('ここみらい公式Instagram'),
            onTap: () {
              _launchURL(
                  'https://www.instagram.com/kokomiraichannel.official/');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('シュンスケのX'),
            onTap: () {
              _launchURL('URL');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('ソウのX'),
            onTap: () {
              _launchURL('URL');
            },
          ),
        ],
      ),
    );
  }
}
