import 'package:cookery_book/widgets/product_form.dart';
import 'package:cookery_book/widgets/filters.dart';
import 'package:flutter/material.dart';
import 'package:cookery_book/utils/db_helper.dart';
import 'package:cookery_book/models/data.dart';
import 'package:cookery_book/widgets/card.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:collection/collection.dart';



  Map<String, bool> mealTypeFilter = {
    'breakfast': true,
    'lunch': true,
    'dinner': true,
    'dessert': true,
  };
  String filterQuery = '';


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
    // final ThemeData theme =  Theme.of(context);
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
        // NavigationDestination(
        //   icon: Icon(Icons.filter_alt),
        //   label: 'Filter by',
        // ),
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
      // ShoppingListPage(),
      Text("Shop List"),
      // Filter Page
      // FilterDishWidget(mealTypeFilter: mealTypeFilter, filters: filters),
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

    // Global variables
  final dbHelper = DatabaseHelper();
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

  final dbHelper = DatabaseHelper();
  // List of lists [Dish, quantity], 
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
// class ShoppingListPage extends StatefulWidget {
//   ShoppingListPage({super.key});


//   @override
//   State<ShoppingListPage> createState() => _ShoppingListPageState();
// }

// class _ShoppingListPageState extends State<ShoppingListPage> {

//   List<Ingredient> products = [];

//   List<Ingredient> getProductList(){
//     List<Ingredient> products = [];
//     for (var dish in widget.dishes){
//       if (dish.selected){
//         for (var ing in dish.ingredients){
//           if (products.isEmpty){
//             products.add(ing * dish.quantity);
//           }
//           else {
//             final thisIng = products.firstWhereOrNull((Ingredient element) => element.name == ing.name);
//             if (thisIng != null){
//               ing = ing * dish.quantity + thisIng;
//               products.remove(thisIng);
//               products.add(ing);
//             } else {
//               products.add(ing * dish.quantity);
//             }
//           }
//         }
//       }
//     }
//     return products;
//   }

//   @override
//   void initState() {
//     super.initState();
//     products = getProductList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           var prod = await showDialog(
//             context: context,
//             builder: (BuildContext context) => AddProduct(),
//           );
//           if (prod != null){
//             setState(() {
//               products.add(Ingredient(name: prod['name'], quantity: prod['quantity'], unit: prod['unit']));
//             });
//           }
//         },
//         child: const Icon(Icons.add_shopping_cart),
//       ),
//       body: ListView.builder(
//           itemCount: products.length,
//           itemBuilder: (BuildContext context, int index) {
//             return ListTile(
//                 leading: const Icon(Icons.shopping_cart, color: Colors.green,),
//                 trailing: Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   spacing: 2, 
//                   mainAxisSize: MainAxisSize.min,      
//                   children: <Widget>[
//                   IconButton(onPressed: (){
//                     setState(() {
//                       products.removeAt(index);
//                     });
//                   }, icon:  Icon(
//                     Icons.delete,
//                     color: Colors.red,  )
//                     ),
//                     InputQty(
//                       initVal: products[index].quantity,
//                       minVal: 0,
//                       steps: 1,
//                       onQtyChanged: (val) {
//                         products[index].quantity = val;
//                       },
//                     ),
//                     Text(products[index].unit),
//                   ]
//                 ),
//               title: Text(products[index].name),
//             );
//           }),
//     );
//   }
// }
// ----------------------------------------------------------