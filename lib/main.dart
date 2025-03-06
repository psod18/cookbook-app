import 'package:cookery_book/widgets/product_form.dart';
import 'package:cookery_book/widgets/filename_dialog.dart';
import 'package:cookery_book/widgets/filters.dart';
import 'package:flutter/material.dart';
import 'package:cookery_book/utils/db_helper.dart';
import 'package:cookery_book/utils/filemanager.dart';
import 'package:cookery_book/models/data.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:collection/collection.dart';
import 'dart:convert';


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
      DishForm(),
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
  FilterState filterState = FilterState();


  
  @override
  void initState() {
    super.initState();
    loadUserMenu();
    }


  Future<List<Dish>> loadUserMenu () async {
    List<Dish> data = await dbHelper.dishes();
    List<Dish> dishes = [];
    for (var dish in data){
      if (filterDishes(dish)){
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
  bool filterDishes(Dish dish){
      bool selected = true;
      selected = filterState.mealTypeFilter[dish.mealType] == true;
      if (filterState.filterQuery.isNotEmpty) {
        selected = selected & containsSubstring(dish, filterState.filterQuery);
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
          await showDialog(
            context: context,
            builder: (BuildContext context) => SetFilterDialog(),
          );
          setState(() {
            loadUserMenu();
          });
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
                    MaterialPageRoute(builder: (context){
                      return ViewShoppingList(fileName: shopLists[index],);
                      }),
                  );
                  loadShopList();
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

  void _onBackPressed() async {
    // save the product list to the file
    Map<String, dynamic> shopList = {
      'dishes': dishes,
      'products': products.map((ing) => ing.toMap()).toList(),
    };
    await writeShopList(widget.fileName, shopList);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (result, resultData) {
        print('Pop invoked with result: $result, data: $resultData');
        _onBackPressed();
        Navigator.maybePop(context);
      },
      child: Scaffold(
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
                              Navigator.pop(context);
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _onBackPressed();
              Navigator.maybePop(context);
            },
          ),
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
              return  ListTile(
                  horizontalTitleGap: 0,
                  contentPadding: const EdgeInsets.fromLTRB(4, 0, 6, 0),
                  dense: true,
                  visualDensity: const VisualDensity(horizontal: -3, vertical: 1),
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
                      spacing: 2, 
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                      IconButton(onPressed: (){
                        setState(() {
                          products.removeAt(index);
                        });
                      }, icon:  Icon(
                        Icons.delete,
                        color: Colors.red,  )
                        ),
                        SizedBox(
                          width: 100,
                          child: InputQty(
                            qtyFormProps: QtyFormProps(
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              enableTyping: true,
                            ),
                            decoration: QtyDecorationProps(
                              // qtyStyle: QtyStyle.btnOnRight,
                              fillColor: Colors.grey[200],
                              orientation: ButtonOrientation.vertical,
                              isBordered: true,
                            ),
                            initVal: products[index].quantity,
                            minVal: 0,
                            steps: 1,
                            onQtyChanged: (val) {
                              products[index].quantity = val;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(products[index].unit.padRight(4, ' '), style: const TextStyle(fontSize: 12),),
                        ),
                      ]
                    ),
                  title: Text(products[index].name, textAlign: TextAlign.start, style: TextStyle(fontSize: 14, fontWeight: products[index].checked ? FontWeight.normal : FontWeight.bold ),),
              );
            }),
      ),
    );
  }
}

// ----------- Dish card --------------------------------

class DishCard extends StatefulWidget {
  DishCard({required this.dish, required this.cardIndex, required this.cardsTotal});
  final Dish dish;
  final int cardIndex;
  final int cardsTotal;

@override
State<StatefulWidget> createState() => _DishCardState();

}


class _DishCardState extends State<DishCard> {

  final dbHelper = DatabaseHelper();
  List<int> menuIdxs = [];

  Color mealTypeColor(String mealType){
    switch(mealType){
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.red;
        case 'dessert':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

    @override
  void initState() {
    super.initState();
    loadMenuIdxs();
    }


  void loadMenuIdxs () async {
    final data = await dbHelper.menuIds();
    setState(() {
      menuIdxs = data;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: mealTypeColor(widget.dish.mealType), width: 8.0),
        color: Color.fromARGB(255, 243, 213, 148),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      margin: EdgeInsets.all(12),
      height: 450,
      width: 300,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        floatingActionButton:  FloatingActionButton.small(
          onPressed: (){
            setState(() {
                // add or remove to menu table in db
                menuIdxs.contains(widget.dish.id) ? {menuIdxs.remove(widget.dish.id), dbHelper.deleteMenu(widget.dish.id!) }: {menuIdxs.add(widget.dish.id!), dbHelper.insertMenu(widget.dish.id!, 1)};                
            });
          },
          backgroundColor: menuIdxs.contains(widget.dish.id)  ? Colors.green : const Color.fromARGB(255, 245, 175, 175),
          child: menuIdxs.contains(widget.dish.id) ? Icon(Icons.done) : Icon(Icons.add),
        ),
      body:        
        Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: 
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('${widget.cardIndex} / ${widget.cardsTotal}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Align(
              alignment: Alignment.center,
              child:Center(
                child: TextButton(
                  onPressed: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(widget.dish.name),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text("How to cook:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              Text(widget.dish.recipe, textAlign: TextAlign.justify, style: TextStyle(fontSize: 16),),
                              SizedBox(height: 15.0,),
                              Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              for (var i in widget.dish.ingredients)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(i.toString(), style: TextStyle(fontStyle: FontStyle.italic),),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    widget.dish.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                    ),
                  )

                ),
              ),
            ),
            SizedBox(
              height: 150.0,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                widget.dish.mealType,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for(var t in widget.dish.tags)
                      Chip(
                        label: Text(t),
                        backgroundColor: Colors.lightGreen[500],
                      ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------- Edit Dish -------------------------

class DishForm extends StatefulWidget {
  // Dish? dish;
  final int? dishId;

  // DishForm({super.key, this.dish});
  DishForm({super.key, this.dishId});


  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm>{
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController recipeController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  List<Ingredient> ingredients = <Ingredient>[];
  
  // for add ingredients form
  TextEditingController newIngredientNameController = TextEditingController();
  int newIngredientQuantity = 1;
  TextEditingController newIngredientUnitControler = TextEditingController();
  

  static final List<DropdownMenuEntry<String>> entries = UnmodifiableListView<DropdownMenuEntry<String>>(
    ['g', 'ml', 'unit'].map<DropdownMenuEntry<String>>(
      (String unit) => DropdownMenuEntry(value: unit, label: unit),
    ),
  );

  static const mealTypes = ['breakfast', 'lunch', 'dinner', 'dessert'];
  String? dropdownValue;

  Dish? dish;

  getDish() async {
    if (widget.dishId != null){
      dish = await dbHelper.dish(widget.dishId!);
    }
    setState(() {
      nameController.text = dish?.name ?? '';
      recipeController.text = dish?.recipe ?? '';
      tagsController.text = dish?.tags.join(' ,') ?? '';
      dropdownValue = dish?.mealType ?? 'breakfast';
      newIngredientUnitControler.text = 'g';
      newIngredientQuantity = 1;
      // extend ingredients with dish ingredients if dish is not null
      List<Ingredient> _ingredients = dish?.ingredients ?? <Ingredient>[];
      ingredients = List.from(_ingredients)..addAll(ingredients);
    });
  }

  @override
  void initState() {
    super.initState();
    getDish();
  }


  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<String>> options = UnmodifiableListView<DropdownMenuEntry<String>>(
      mealTypes.map<DropdownMenuEntry<String>>(
        (String name) => DropdownMenuEntry<String>(value: name, label: name)
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: dish != null ? Text('Edit Dish') : Text('Add New Dish'),
        backgroundColor: const Color.fromARGB(255, 114, 189, 108),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 3, color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                // Set border for focused state
                focusedBorder: OutlineInputBorder(
                  borderSide:  BorderSide(width: 3, color: Colors.orange),
                  borderRadius: BorderRadius.circular(15),
                )
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                

                controller: recipeController,
                minLines: 10,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Recipe',

                 enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 3, color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                // Set border for focused state
                focusedBorder: OutlineInputBorder(
                  borderSide:  BorderSide(width: 3, color: Colors.orange),
                  borderRadius: BorderRadius.circular(15),
                )
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 3, color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                // Set border for focused state
                focusedBorder: OutlineInputBorder(
                  borderSide:  BorderSide(width: 3, color: Colors.orange),
                  borderRadius: BorderRadius.circular(15),
                )

                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tags';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownMenu<String>(
                label: Text('Meal Type'),
                expandedInsets: EdgeInsets.all(4),
                initialSelection: dropdownValue,
                onSelected: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    dropdownValue = value!;
                  });
                },
                dropdownMenuEntries: options,
              ),
              SizedBox(height: 10,),
              
              Text('Add Ingredients:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              SizedBox(height: 10,),
          //  add ingerdient part
              TextFormField(
                controller: newIngredientNameController,
                decoration: InputDecoration(
                  labelText: 'Add new ingredient',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 3, color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                // Set border for focused state
                focusedBorder: OutlineInputBorder(
                  borderSide:  BorderSide(width: 3, color: Colors.green),
                  borderRadius: BorderRadius.circular(15),
                )

                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Provide ingredient name';
                  }
                  return null;
                },
              ),
          SizedBox(height: 10,),
          IntrinsicHeight(
           child:Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: InputQty.int(
                  decoration: QtyDecorationProps(
                    qtyStyle: QtyStyle.btnOnRight,
                    isBordered: false,
                  ),
                  initVal: newIngredientQuantity,
                  minVal: 1,
                  steps: 1,
                  onQtyChanged: (val) {
                    setState(() {
                      newIngredientQuantity = val;
                    });
                  },
                ),
              ),
              DropdownMenu<String>(
                initialSelection: newIngredientUnitControler.text,
                controller: newIngredientUnitControler,
                requestFocusOnTap: true,
                label: const Text('Unit'),
                onSelected: (String? value) {
                  setState(() {
                    newIngredientUnitControler.text = value!;
                  });
                },
                dropdownMenuEntries: entries,
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, // background color
                    backgroundColor: Colors.green, // text color
                    // padding: EdgeInsets.all(10.0),
                    side: BorderSide(color: Colors.orange, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (newIngredientNameController.text.isNotEmpty){
                        ingredients.add(Ingredient(
                          name: newIngredientNameController.text,
                          quantity: newIngredientQuantity,
                          unit: newIngredientUnitControler.text,
                        ));
                      newIngredientNameController.clear();
                      newIngredientQuantity = 1;
                      newIngredientUnitControler.text = 'g';
                      }
                    });
                  },
                  child: Text(
                    "Add",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          ),
            
            // list all products (add delet/edit button)
            for (var ingredient in ingredients)
              Row(
                children: [
                  // replace with tail listview
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400],),
                    onPressed: () {
                      setState(() {
                        ingredients.remove(ingredient);
                      });
                    },
                  ),
                  Expanded(
                    child: Text(ingredient.toString(), style: TextStyle(fontSize: 16),),
                  ),
                ],
            ),


          ],
          ), 
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final dish = Dish(
              // id: widget.dish?.id,
              id: widget.dishId,
              name: nameController.text,
              mealType: dropdownValue!,
              recipe: recipeController.text,
              tags: tagsController.text.split(',').map((e) => e.trim()).toList(),
              ingredients: <Ingredient>[],
            );
            // if (widget.dish != null){
            if (widget.dishId != null){
              // await dbHelper.updateDish(dish);
              print('Update Dish $dish');
            } else {
              // await dbHelper.insertDish(dish);
              print('Insert Dish $dish');
            }
            Navigator.pop(context);
          }
        },
        child: const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}