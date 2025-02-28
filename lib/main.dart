import 'package:cookery_book/widgets/product_form.dart';
import 'package:cookery_book/widgets/filename_dialog.dart';
import 'package:cookery_book/widgets/filters.dart';
import 'package:flutter/material.dart';
import 'package:cookery_book/utils/db_helper.dart';
import 'package:cookery_book/utils/filemanager.dart';
import 'package:cookery_book/models/data.dart';
import 'package:cookery_book/widgets/card.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:collection/collection.dart';
import 'dart:convert';



Map<String, bool> mealTypeFilter = {
  'breakfast': true,
  'lunch': true,
  'dinner': true,
  'dessert': true,
};
String filterQuery = '';

final dbHelper = DatabaseHelper();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  int currentPageIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookery Book!',
      theme: ThemeData(
        useMaterial3: true,
      ),
    home: Scaffold(
    appBar: AppBar(
        title: const Text('Cookery Book'),
        backgroundColor: const Color.fromARGB(255, 114, 189, 108),
        ),
    bottomNavigationBar: NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });
      },
      indicatorColor: Colors.amber,
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[

        NavigationDestination(
          icon: Icon(Icons.menu_book),
          label: 'CookBook',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.note_add),
          label: 'New Dish',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_basket),
          label: 'Shop List',
        ),
      ],
    backgroundColor: const Color.fromARGB(255, 114, 189, 108),
    ),
    body: <Widget>[
      // CookBook Page
      MyMenuPage(),
      // Selected Menu Page
      SelectedMenuPage(),
      // Add Dish Page
      Text("Add New Dish"),
      // Shopping list Page
      ShoppingListPage(),
    ]
      [currentPageIndex],
    )
  );
  }
}


// ----------- Menu Widget --------------------------------
class MyMenuPage extends StatefulWidget {
  MyMenuPage({super.key});

  @override
  State<MyMenuPage> createState() => _MyMenuPageState();
}

class _MyMenuPageState extends State<MyMenuPage> {

  List<Dish> dishes = []; // List to store the dishes


  
  @override
  void initState() {
    super.initState();
    loadUserMenu();
    }


  Future<List<Dish>> loadUserMenu () async {
    List<Dish> data = await dbHelper.dishes();
    List<Dish> dishes = [];
    for (var dish in data){
      if (filterDishes(dish, filterQuery, mealTypeFilter)){
        dishes.add(dish);
      }
    }
    setState(() {
      this.dishes = dishes;
    });
    return dishes;
  }


  
  bool containsSubstring(Dish dish, String query){
    return dish.name.toLowerCase().contains(query.toLowerCase()) | 
    dish.ingredients.any((ing) => ing.name.toLowerCase().contains(query.toLowerCase()) |
    dish.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())));
  }


  // Getter for dishes
  bool filterDishes(Dish dish, String filterQuery, Map<String, bool> mealTypeFilter){
      bool selected = true;
      selected = mealTypeFilter[dish.mealType] == true;
      if (filterQuery.isNotEmpty) {
        selected = selected & containsSubstring(dish, filterQuery);
      }
      return selected;
  }

  @override
  Widget build(BuildContext context) {
    var numOfVisibleDishes = dishes.length;
    var cardCount = 0;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.filter_alt),
        onPressed: () async {
          filterQuery = await showDialog(
            context: context,
            builder: (BuildContext context) => SetFilterDialog(mealTypeFilter: mealTypeFilter, filterQuery: filterQuery),
          );
          loadUserMenu();
          // loadUserMenute(() => _MyMenuPageState());
        },
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var dish in dishes)
                DishCard(dish: dish, cardIndex: ++cardCount, cardsTotal: numOfVisibleDishes),
            ],
          ),
        )
    );
  }
}
// ----------------------------------------------------------

// ----------- Selected Menu --------------------------------
class SelectedMenuPage extends StatefulWidget {
  SelectedMenuPage({super.key});



  @override
  State<SelectedMenuPage> createState() => _SelectedMenuPageState();
}

class _SelectedMenuPageState extends State<SelectedMenuPage> {

  List<List<dynamic>> selectedDishes = []; // List to store the dishes

  @override
  void initState() {
    super.initState();
    loadMenu();
    }


  void loadMenu () async {
    final data = await dbHelper.menu();
    setState(() {
      selectedDishes = data;
    });
  }

  (List<String>, List<Ingredient>) getProductList(){
    List<Ingredient> products = [];
    List<String> dishes = [];
    for (var dish in selectedDishes){
      dishes.add(dish[0].name);
      for (var ing in dish[0].ingredients){
        if (products.isEmpty){
          products.add(ing * dish[1]);
        }
        else {
          final thisIng = products.firstWhereOrNull((Ingredient element) => element.name == ing.name);
          if (thisIng != null){
            ing = ing * dish[1] + thisIng;
            products.remove(thisIng);
            products.add(ing);
          } else {
            products.add(ing * dish[1]);
          }
        }
      }
    }
    return (dishes, products);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
        label: const Text("Build\nShoplist", textAlign: TextAlign.center,),
        onPressed: () async {
          var fname = await showDialog(
            context: context,
            builder: (BuildContext context) => FileNameDialog(),
          );
          if (fname != null){
            // Generate product list and save it to a file
            var (List<String> dishes, List<Ingredient> products) = getProductList();
            Map<String, dynamic> shopList = {
              'dishes': dishes,
              // convert the list of ingredients to a list of maps
              'products': products.map((ing) => ing.toMap()).toList(),
            };
            writeShopList(fname, shopList);
          }
        },
        ),
      body: ListView.builder(
          itemCount: selectedDishes.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                leading: const Icon(Icons.dining),
                trailing: Row(    
                  mainAxisSize: MainAxisSize.min,      
                  children: <Widget>[
                  IconButton(onPressed: (){
                    dbHelper.deleteMenu(selectedDishes[index][0].id);
                    loadMenu();
                  }, icon:  Icon(
                    Icons.delete,
                    color: Colors.red,  )
                    ),
                    InputQty.int(
                      maxVal: 99,
                      initVal: selectedDishes[index][1],
                      minVal: 1,
                      steps: 1,
                      onQtyChanged: (val) {
                        dbHelper.updateMenu(selectedDishes[index][0].id, val);
                      },
                    ),
                  ]
                ),
                title: Text(selectedDishes[index][0].name),);
          }),
    );
  }
}
// ------------------------ Shopping List -----------------------
class ShoppingListPage extends StatefulWidget {
  ShoppingListPage({super.key});


  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<String> shopLists = <String>[];

  @override
  void initState() {
    super.initState();
    loadShopList();
    }


  void loadShopList () async {
    List<String> data = await listShopLists();
    setState(() {
      shopLists = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: shopLists.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                leading: const Icon(Icons.list),
                trailing: Row(    
                  mainAxisSize: MainAxisSize.min,      
                  children: <Widget>[
                  IconButton(onPressed: (){
                    deleteShopList(shopLists[index]);
                    setState(() {
                      shopLists.removeAt(index);
                    });
                  }, icon:  Icon(
                    Icons.delete,
                    color: Colors.red,  )
                    ),
                  ]
                ),
                title: Text(shopLists[index]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewShoppingList(fileName: shopLists[index],)),
                  );
                },
                );
          }),
    );
  }

}


class ViewShoppingList extends StatefulWidget {
  ViewShoppingList({super.key, required this.fileName});
  final String fileName;


  @override
  State<ViewShoppingList> createState() => _ViewShoppingList();
}

class _ViewShoppingList extends State<ViewShoppingList> {

  // read product list from file
  List<Ingredient> products = [];
  List<String> dishes = [];

  void getProductList() async {
    List<Ingredient> prod_t = [];
    List<Ingredient> prod_f = [];
    List<String> _dishes = [];
    String value = await readShopList(widget.fileName);
    var data = json.decode(value);
    for(var dish in data['dishes']){
      _dishes.add(dish);
    }

    for(var ing in data['products']){
      Ingredient prod = Ingredient(
        name: ing['name'] as String,
        quantity: ing['quantity'],
        unit: ing['unit'] as String,
        checked: ing['checked'] == 1 ? true : false,
      );
      if (prod.checked){
        prod_t.add(prod);
      } else {
        prod_f.add(prod);
      }
    }
    setState(() {
      products = List.from(prod_f)..addAll(prod_t);
      dishes = _dishes;
    });
  }

  @override
  void initState() {
    super.initState();
    getProductList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
            IconButton(
              onPressed: (){
                showDialog <void> (
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Menu:", textAlign: TextAlign.center,),
                      content: Text(dishes.join(", "), textAlign: TextAlign.center,),
                      actions: [
                        TextButton(
                          child: const Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },  
              icon: Icon(Icons.info),
            ),
            Text(widget.fileName),
          ],
        ) ,
        backgroundColor: const Color.fromARGB(255, 114, 189, 108),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var prod = await showDialog(
            context: context,
            builder: (BuildContext context) => AddProduct(),
          );
          if (prod != null){
            setState(() {
              products.add(Ingredient(name: prod['name'], quantity: prod['quantity'], unit: prod['unit']));
            });
          }
        },
        child: const Icon(Icons.add_shopping_cart),
      ),
      body: ListView.builder(
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                leading: IconButton(
                  icon: Icon(products[index].checked ? Icons.shopping_cart : Icons.check_box_outline_blank),
                  onPressed: ()
                    {
                      setState(() {
                        products[index].checked = !products[index].checked;

                        if (products[index].checked){

                          products.add(products[index]);
                          products.removeAt(index);
                        } else {
                          products.insert(0, products[index]);
                          products.removeAt(index + 1);
                        }
                      });
                    },
                  ),
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 2, 
                  mainAxisSize: MainAxisSize.min,      
                  children: <Widget>[
                  IconButton(onPressed: (){
                    setState(() {
                      products.removeAt(index);
                    });
                  }, icon:  Icon(
                    Icons.delete,
                    color: Colors.red,  )
                    ),
                    InputQty(
                      initVal: products[index].quantity,
                      minVal: 0,
                      steps: 1,
                      onQtyChanged: (val) {
                        products[index].quantity = val;
                      },
                    ),
                    Text(products[index].unit),
                  ]
                ),
              title: Text(products[index].name),
            );
          }),
    );
  }
}
// ----------------------------------------------------------