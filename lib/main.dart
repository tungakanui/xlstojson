import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

final Uri _url = Uri.parse('https://fb.com/tungakanuiii');

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XLS to JSON',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

String getPrettyJSONString(jsonObject) {
  var encoder = const JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String fileName = "";
  FilePickerResult? result;
  Map<String, dynamic> output = {};
  List<List<String?>> twoDirArray = [];
  int maxRows = 0;
  int maxCols = 0;

  void onSelect() {
    var bytes = result!.files.first.bytes ?? [] as List<int>;
    var excel = Excel.decodeBytes(bytes);

    final sheetKey = excel.tables.keys.first;
    final sheet = excel.tables[sheetKey];

    maxCols = sheet?.maxCols ?? 0;
    maxRows = sheet?.maxRows ?? 0;

    twoDirArray.clear();
    twoDirArray = List.generate(
        maxRows, (i) => List.generate(maxCols, (j) => null, growable: false),
        growable: false);

    print(twoDirArray);

    print("maxCols: $maxCols");
    print("maxRows: $maxRows");

    if (maxCols > 0 && maxRows > 0) {
      for (var row in sheet!.rows) {
        for (var element in row) {
          if (element != null) {
            twoDirArray[element.rowIndex][element.colIndex] =
                element.value.toString();
          }
        }
      }
    }
    setState(() {
      output = getObject(startRow: 1, endRow: maxRows - 1, startCol: 0);
    });
  }

  // void process(int r, int c, int maxR, int maxC) {
  //   while (r < maxRows) {}
  // }

  Map<String, dynamic> getObject(
      {required int startRow, required int endRow, required int startCol}) {
    Map<String, dynamic> object = {};
    int i = startRow;
    print("endRow: $endRow");
    while (i <= endRow) {
      final String? key = twoDirArray[i][startCol];
      final String keyString = "${twoDirArray[i][startCol]}";
      if (key != null) {
        if (twoDirArray[i][maxCols - 2] == "int") {
          // object[keyString] = getRandomInt();
          object[keyString] = int.tryParse(twoDirArray[i][maxCols - 1] ?? "0");
          // i++;
        } else if (twoDirArray[i][maxCols - 2] == "double") {
          // object[keyString] = getRandomDouble();
          object[keyString] =
              double.tryParse(twoDirArray[i][maxCols - 1] ?? "0.0");
          // i++;
        } else if (twoDirArray[i][maxCols - 2] == "string") {
          // object[keyString] = getRandomString(10);
          // i++;
          object[keyString] = twoDirArray[i][maxCols - 1] ?? "string";
        } else if (twoDirArray[i][maxCols - 2] == "id") {
          // object[keyString] = getRandomString(10);
          object[keyString] = twoDirArray[i][maxCols - 1] ?? "id";
          // i++;
        } else if (twoDirArray[i][maxCols - 2] == "date") {
          // object[keyString] = getRandomDate().toString();
          object[keyString] = twoDirArray[i][maxCols - 1] ?? "date";
          // i++;
        } else if (twoDirArray[i][maxCols - 2] == "boolean") {
          // object[keyString] = getRandomDouble();
          object[keyString] = twoDirArray[i][maxCols - 1] ?? true;
          // i++;
        }
        // else if (twoDirArray[i][maxCols - 1] == null) {
        //   object[keyString] = null;
        //   // i++;
        // }
        else if (twoDirArray[i][maxCols - 2] == "number") {
          // object[keyString] = getRandomDouble();
          object[keyString] = int.tryParse(twoDirArray[i][maxCols - 1] ?? "0");
          // i++;
        } else if (twoDirArray[i][maxCols - 2] == "object") {
          // print("checking: row: $i col: $startCol");
          int endIndex = i + 1;
          while (twoDirArray[endIndex][startCol] == null && endIndex < endRow) {
            // print("checking: row: $endIndex col: ${startCol} current i: $i");
            print("checking row: $endIndex col: $startCol");
            endIndex++;
          }

          print(
              " startRow: ${i + 1}, endRow: $endIndex, startCol: ${startCol + 1}");
          Map<String, dynamic> res = getObject(
              startRow: i + 1, endRow: endIndex, startCol: startCol + 1);

          object[keyString] = res;
          i = endIndex - 1;
        } else if (twoDirArray[i][maxCols - 2] == "array") {
          // print("checking: row: $i col: ${startCol} current i: $i");
          int endIndex = i + 1;
          while (twoDirArray[endIndex][startCol] == null && endIndex < endRow) {
            // print("checking: row: $endIndex col: ${startCol} current i: $i");
            endIndex++;
            print(endIndex);
          }

          Map<String, dynamic> res = getObject(
              startRow: i + 1, endRow: endIndex, startCol: startCol + 1);

          print(
              " startRow: ${i + 1}, endRow: ${endIndex - 1}, startCol: ${startCol + 1}");
          object[keyString] = [res];
          i = endIndex - 1;
        } else {
          object[keyString] = twoDirArray[i][maxCols - 1] ?? "value";
          // i++;
        }
      }

      i++;
    }
    return object;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: CupertinoButton(
        onPressed: () {
          FlutterClipboard.copy(getPrettyJSONString(output));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Copied!",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF59114D),
            ),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFe98a15),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(16),
          child: const Icon(
            Icons.copy,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          CupertinoButton(
            onPressed: () async {
              result = await FilePicker.platform.pickFiles();
              if (result != null) {
                if (result!.isSinglePick) {
                  setState(() {
                    fileName = result!.files.first.name;
                    onSelect();
                  });
                }
                //
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFe98a15),
              ),
              child: const Text(
                "Choose file",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 22, color: Color(0xFF003B36)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: HighlightView(
                    // The original code to be highlighted
                    getPrettyJSONString(output),

                    // Specify language
                    // It is recommended to give it a value for performance
                    language: 'json',

                    // Specify highlight theme
                    // All available themes are listed in `themes` folder
                    theme: vs2015Theme,

                    // Specify padding
                    padding: const EdgeInsets.all(12),

                    // Specify text style
                    textStyle: const TextStyle(
                      fontFamily: 'My awesome monospace font',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'by @tungakanui ',
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: 'Facebook',
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (!await launchUrl(_url)) {
                          throw 'Could not launch $_url';
                        }
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
