import 'package:path_provider/path_provider.dart';
import 'package:cookery_book/models/data.dart' show Ingredient;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localShopList async {
  final path = await _localPath;
  return File('$path/shoplist.json');
}

  Future<File> writeShopList(List<Ingredient> ingredients) async {
    final file = await _localShopList;

    // Write the file 
    return file.writeAsString(jsonEncode(ingredients.map((ing) => ing.toMap()).toList()));
  }

  Future<List<Map>> readShopList() async {
    try {
      final file = await _localShopList;

      // Read the file
      String contents = await file.readAsString();

      return json.decode(contents).map((ing) => Ingredient(
            name: ing['name'] as String,
            quantity: ing['quantity'],
            unit: ing['unit'] as String,
          ))
          .toList();
    } catch (e) {
      // If encountering an error, return 0
      return [];
    }
  }


Future<String> readJsonFile(String filePath) async {
  String jsonString = await rootBundle.loadString(filePath);
  return jsonString;
}