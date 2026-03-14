import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

final _validFilename = RegExp(r'^[a-zA-Z0-9_\-]+$');

String _sanitizeFilename(String name) {
  if (!_validFilename.hasMatch(name)) {
    throw ArgumentError('Invalid filename: $name');
  }
  return name;
}

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  // List all files in the shoplists directory
  Future<List<String>> listShopLists() async {
    final String path = await _localPath;
    final Directory dir = Directory('$path/shoplists');
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return dir.listSync().map((f) => basenameWithoutExtension(f.path)).toList();
  }

  Future<File> _localShopList(String fname) async {
  final String path = await _localPath;
  final safeName = _sanitizeFilename(fname);
  File f = File('$path/shoplists/$safeName.json');
  if (!f.existsSync()) {
    f.createSync(recursive: true);
  }
  return f;
}

  Future<File> writeShopList(String filename, Map<String, dynamic> shoplist) async {
    final file = await _localShopList(filename);

    // overwrite the file with the new list of ingredients
    return file.writeAsString(jsonEncode(shoplist));
    // return file.writeAsString(jsonEncode(ingredients.map((ing) => ing.toMap()).toList()));
  }

  Future<String> readShopList(String filename) async {
    try {
      final String path = await _localPath;
      final safeName = _sanitizeFilename(filename);
      final File file = File('$path/shoplists/$safeName.json');

      // Read the file
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      // If encountering an error, return '[]'
      return '[]';
    }
  }

  Future<void> deleteShopList(String filename) async {
    final String path = await _localPath;
    final safeName = _sanitizeFilename(filename);
    final File file = File('$path/shoplists/$safeName.json');
    file.deleteSync();
  }

Future<String> readJsonFile(String filePath) async {
  String jsonString = await rootBundle.loadString(filePath);
  return jsonString;
}