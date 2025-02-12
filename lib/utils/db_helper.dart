import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:cookery_book/models/data.dart';
import 'package:cookery_book/utils/filemanager.dart' show readJsonFile;


// Database helper class
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  factory DatabaseHelper() {
    return _instance;
  }
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'cookery_book.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create Dish table
    await db.execute(
      '''
      CREATE TABLE dishes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealType TEXT,
        name TEXT,
        recipe TEXT,
        tags TEXT,
        ingredients TEXT
      );
      '''
    );
    await db.execute(
      '''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dish_id INTEGER,
        quantity INTEGER,
        CONSTRAINT fk_dish_id
          FOREIGN KEY (dish_id)
          REFERENCES dishes (id)
          ON DELETE CASCADE
      );
      '''
    );

    // prepopulate a few rows (consider using a transaction)
    final jsonData = await readJsonFile('assets/menu.json');
    List<dynamic> parsedJson = json.decode(jsonData);
    for (var dish in parsedJson){
        await db.rawInsert('''
          INSERT INTO dishes (name, mealType, recipe, tags, ingredients)
          VALUES (?, ?, ?, ?, ?);
        ''', [
          dish['name'],
          dish['mealType'],
          dish['recipe'],
          jsonEncode(dish['tags']),
          jsonEncode(dish['ingredients']),
        ]);
    }
  }

  // CRUD operations for dishes
  Future<int> insertDish(Dish dish) async {
    final db = await database;
    return await db.insert('dishes', dish.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Dish> dish(int id) async {
    final db = await database;
    final List<Map<String, Object?>> dishMaps = await db.query(
      'dishes',
      where: 'id = ?',
      whereArgs: [id],
    );
    List<Ingredient> ingredients = [];
    for (var ing in jsonDecode(dishMaps.first['ingredients'] as String)){
      Ingredient _ing = Ingredient(
        name: ing['name'] as String,
        quantity: ing['quantity'] as num,
        unit: ing['unit'] as String,
      );
      ingredients.add(_ing);
    }
    List<String> tags = [];
      for (var tag in jsonDecode(dishMaps.first['tags'] as String)){
          tags.add(tag.toLowerCase());
      }  
    return Dish(
      id: dishMaps[0]['id'] as int,
      name: dishMaps[0]['name'] as String,
      mealType: dishMaps[0]['mealType'] as String,
      recipe: dishMaps[0]['recipe'] as String,
      tags: tags,
      ingredients: ingredients,
    );
  }

  Future<List<Dish>> dishes() async {
    final db = await database;
    final List<Map<String, Object?>> dishMaps = await db.query('dishes');
    List<Dish> dishes = [];

    for (var dishMap in dishMaps){

      List<Ingredient> ingredients = [];
      for (var ing in jsonDecode(dishMap['ingredients'] as String)){
        Ingredient _ing = Ingredient(
          name: ing['name'] as String,
          quantity: ing['quantity'] as num,
          unit: ing['unit'] as String,
        );
        ingredients.add(_ing);
      }
      List<String> tags = [];
        for (var tag in jsonDecode(dishMap['tags'] as String)){
            tags.add(tag.toLowerCase());
        }  
      dishes.add(Dish(
        id: dishMap['id'] as int,
        name: dishMap['name'] as String,
        mealType: dishMap['mealType'] as String,
        recipe: dishMap['recipe'] as String,
        tags: tags,
        ingredients: ingredients,
      ));
    }
    return dishes;
  }

  Future<void> updateDish(Dish dish) async {
    final db = await database;
    await db.update(
      'dishes',
      dish.toMap(),
      where: 'id = ?',
      whereArgs: [dish.id],
    );
  }

  Future<void> deleteDish(int id) async {
    final db = await database;
    await db.delete(
      'dishes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for menu
  Future<void> insertMenu(int dishId, int quantity) async {
    final db = await database;
    await db.insert('menu', {
      'dish_id': dishId,
      'quantity': quantity,
    });
  }


  // Custom SQL query to get all dishes from menu and their quantities
  Future<List<List<dynamic>>> menu() async {
    final db = await database;
    final List<Map<String, Object?>> menuMaps = await db.rawQuery('''
      SELECT dishes.id, dishes.name, dishes.mealType, dishes.recipe, dishes.tags, dishes.ingredients, menu.quantity
      FROM dishes
      JOIN menu ON dishes.id = menu.dish_id
    ''');
    List<List<dynamic>> menu = [];
    for (var menuMap in menuMaps){
      List<Ingredient> ingredients = [];
      for (var ing in jsonDecode(menuMap['ingredients'] as String)){
        Ingredient _ing = Ingredient(
          name: ing['name'] as String,
          quantity: ing['quantity'] as num,
          unit: ing['unit'] as String,
        );
        ingredients.add(_ing);
      }
      List<String> tags = [];
        for (var tag in jsonDecode(menuMap['tags'] as String)){
            tags.add(tag.toLowerCase());
        }  
      menu.add([
        Dish(
          id: menuMap['id'] as int,
          name: menuMap['name'] as String,
          mealType: menuMap['mealType'] as String,
          recipe: menuMap['recipe'] as String,
          tags: tags,
          ingredients: ingredients,
        ),
        menuMap['quantity'] as int
      ]);
    }
    return menu;
  }
  
  // get only the dish ids from the menu
  Future<List<int>> menuIds() async {
    final db = await database;
    final List<Map<String, Object?>> menuMaps = await db.query('menu');
    return [
      for (var menuMap in menuMaps) menuMap['dish_id'] as int
    ];
  }

  Future<void> updateMenu(int dishId, int quantity) async {
    final db = await database;
    await db.update(
      'menu',
      {
        'quantity': quantity,
      },
      where: 'dish_id = ?',
      whereArgs: [dishId],
    );
  }

  Future<void> deleteMenu(int dishId) async {
    final db = await database;
    await db.delete(
      'menu',
      where: 'dish_id = ?',
      whereArgs: [dishId],
    );
  }

}