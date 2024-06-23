// import 'dart:typed_data';
// import 'package:excel/excel.dart';
// import 'package:kokotan/db/database_helper.dart';
// import 'package:flutter/services.dart' show rootBundle;

// Future<void> importExcelToDatabase() async {
//   final dbHelper = DatabaseHelper.instance;

//   try {
//     // Load the Excel file
//     ByteData data = await rootBundle.load("assets/db/dev_kokotan_list.xlsx");
//     var bytes = data.buffer.asUint8List();
//     var excel = Excel.decodeBytes(bytes);

//     // Insert data into SQLite
//     for (var table in excel.tables.keys) {
//       var sheet = excel.tables[table];
//       for (var row in sheet!.rows) {
//         if (row[0]?.value == 'id') continue; // Skip the header row

//         Map<String, dynamic> word = {
//           'id': row.length > 0
//               ? int.tryParse(row[0]?.value.toString() ?? '')
//               : null,
//           'word': row.length > 1 ? row[1]?.value?.toString() : '',
//           'main_meaning': row.length > 2 ? row[2]?.value?.toString() : '',
//           'sub_meaning': row.length > 3 ? row[3]?.value?.toString() : '',
//           'sentence': row.length > 4 ? row[4]?.value?.toString() : '',
//           'sentence_jp': row.length > 5 ? row[5]?.value?.toString() : ''
//         };

//         // Skip rows with missing required fields
//         if (word['id'] == null ||
//             word['word'] == '' ||
//             word['main_meaning'] == '' ||
//             word['sentence'] == '' ||
//             word['sentence_jp'] == '') {
//           continue;
//         }

//         await dbHelper.insertWord(word);
//       }
//     }
//     print('Excel data imported successfully');
//   } catch (e) {
//     print('Error importing Excel data: $e');
//   }
// }
