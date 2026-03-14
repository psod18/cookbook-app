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

  Dish _dishFromMap(Map<String, Object?> map) {
    return Dish(
      id: map['id'] as int,
      name: map['name'] as String,
      mealType: map['mealType'] as String,
      recipe: map['recipe'] as String,
      tags: (jsonDecode(map['tags'] as String) as List)
          .map((tag) => (tag as String).toLowerCase())
          .toList(),
      ingredients: (jsonDecode(map['ingredients'] as String) as List)
          .map((ing) => Ingredient(
                name: ing['name'] as String,
                quantity: ing['quantity'] as num,
                unit: ing['unit'] as String,
              ))
          .toList(),
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'cookery_book.db');
    // Create the database and the tables
    // await deleteDatabase(path); // Uncomment this line to delete the database every time the app starts
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic for future schema changes
  }

  // CRUD operations for dishes
  Future<int> insertDish(Dish dish) async {
    final db = await database;
    final dishMap = dish.toMap();
    return await db.rawInsert('''
          INSERT INTO dishes (name, mealType, recipe, tags, ingredients)
          VALUES (?, ?, ?, ?, ?);
        ''', [
          dishMap['name'],
          dishMap['mealType'],
          dishMap['recipe'],
          dishMap['tags'],
          dishMap['ingredients'],
        ]);
  }

  Future<List<Dish>> filterDishes(List<String> mealTypes, String query) async {
    final db = await database;
    final placeholders = List.filled(mealTypes.length, '?').join(',');
    final cursor = await db.rawQuery(
      "SELECT * FROM dishes WHERE mealType IN ($placeholders) "
      "AND (name LIKE ? OR tags LIKE ? OR ingredients LIKE ?)",
      [...mealTypes, '%$query%', '%$query%', '%$query%'],
    );
    return cursor.map(_dishFromMap).toList();
  }

  Future<Dish> dish(int id) async {
    final db = await database;
    final List<Map<String, Object?>> dishMaps = await db.query(
      'dishes',
      where: 'id = ?',
      whereArgs: [id],
    );
    return _dishFromMap(dishMaps.first);
  }

  Future<List<Dish>> dishes() async {
    final db = await database;
    final List<Map<String, Object?>> dishMaps = await db.query('dishes');
    return dishMaps.map(_dishFromMap).toList();
  }

  Future<int> updateDish(Dish dish) async {
    final db = await database;
    int count = await db.update(
      'dishes',
      dish.toMap(),
      where: 'id = ?',
      whereArgs: [dish.id],
    );
    return count;
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
    return menuMaps.map((menuMap) => [
      _dishFromMap(menuMap),
      menuMap['quantity'] as int,
    ]).toList();
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