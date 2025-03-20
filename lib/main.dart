import 'package:cookery_book/widgets/product_form.dart';
import 'package:cookery_book/widgets/filename_dialog.dart';
import 'package:cookery_book/widgets/filters.dart';
import 'package:flutter/material.dart';
import 'package:cookery_book/utils/db_helper.dart';
import 'package:cookery_book/utils/filemanager.dart';
import 'package:cookery_book/models/data.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:async';
import 'dart:convert';


final dbHelper = DatabaseHelper();

class QuickFilter {
  static final QuickFilter _instance = QuickFilter._internal();
  factory QuickFilter() => _instance;
  QuickFilter._internal();
  
  final values = ["all", "selected", "unselected"];
  int currentIndex = 0;

  get current => values.elementAt(currentIndex);

  get currenIcon{
    switch(current){
      case "all":
        return Icon(Icons.list_alt);
      case "selected":
        return Icon(Icons.done_all);
      case "unselected":
        return Icon(Icons.remove_done);
      default:
        return Icon(Icons.all_inclusive);
    }
  }
  
  void step(){
    currentIndex = (currentIndex + 1) % values.length;
  }
}


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

  FilterState filterState = FilterState();
  QuickFilter quickFilter = QuickFilter();

  List<Dish> dishes = [];
  List<int> menuIdxs = [];


  Future<List<Dish>> loadUserMenu () async {
    final data = await dbHelper.filterDishes(filterState.mealTypeFilter.keys.where((key) => filterState.mealTypeFilter[key] == true).toList() , filterState.filterQuery);

    final menu = await dbHelper.menuIds();
    menuIdxs = menu;

    if (quickFilter.current == "all") {
      for (var dish in data){
        dishes.add(dish);
      }
    } else if (quickFilter.current == "unselected") {
      for(var dish in data){
        if (!menuIdxs.contains(dish.id)){
          dishes.add(dish);
        }
      }
    } else if (quickFilter.current == "selected") {
      for(var dish in data){
        if (menuIdxs.contains(dish.id)){
          dishes.add(dish);
        }
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: loadUserMenu(),
      builder: (BuildContext context, AsyncSnapshot<List<Dish>> snapshot) {
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                child: quickFilter.currenIcon,
                onPressed: () {
                  setState(() {
                    dishes.clear();
                  });
                  quickFilter.step();
                }
              ),
              SizedBox(height: 5.0,),
              FloatingActionButton(
                child: const Icon(Icons.filter_alt),
                onPressed: () 
                  async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) => SetFilterDialog(),
                    );
                  setState(() {
                    dishes.clear();
                  });
                },
              ),
            ]        
          ),


          body: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            scrollDirection: Axis.vertical,
            children: [
            for (var i = 0; i < dishes.length; i++)
              Container(
                  decoration: BoxDecoration(
                  border: Border.all(color: mealTypeColor(dishes[i].mealType), width: 4.0),
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
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i+1} / ${dishes.length}', style: TextStyle(color: Colors.grey), ), // index of the dish
                          IconButton(
                            onPressed: (){
                              setState((){
                                menuIdxs.contains(dishes[i].id) ? {menuIdxs.remove(dishes[i].id), dbHelper.deleteMenu(dishes[i].id!) }: {menuIdxs.add(dishes[i].id!), dbHelper.insertMenu(dishes[i].id!, 1)};
                              });
                            },
                            icon: menuIdxs.contains(dishes[i].id) ? Icon(Icons.done) : Icon(Icons.add),
                            color: menuIdxs.contains(dishes[i].id)  ? const Color.fromARGB(255, 5, 117, 9) : Colors.black,
                          ),
                        ],
                      ), // add/remove to/from selected menu
                    ),
                    TextButton(
                      onPressed: (){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(dishes[i].name,),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text("How to cook:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  Text(dishes[i].recipe, textAlign: TextAlign.justify, style: TextStyle(fontSize: 16),),
                                  SizedBox(height: 15.0,),
                                  Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  for (var i in dishes[i].ingredients)
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
                        dishes[i].name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          color: mealTypeColor(dishes[i].mealType),
                        ),
                      )
                    ), // dish name with button function to show recipe
                    SizedBox(
                    height: 40,
                      child: TextButton(
                        child: Text(dishes[i].mealType, style: TextStyle(fontSize: 12, color: Colors.black),),
                        onPressed: (){
                          // set filter to show only this meal type
                          filterState.mealTypeFilter.updateAll((name, value) => value = false);
                          filterState.mealTypeFilter[dishes[i].mealType] = true;
                          setState(() {
                            dishes.clear();
                          });
                        },
                      ),
                    ),
                    Wrap(
                        children: (dishes[i].tags.length > 3)
                        ? [
                            for (var t in dishes[i].tags.getRange(0, 3))
                              Chip(
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                label: Text('#$t', style: TextStyle(fontSize: 10),),
                                backgroundColor: Colors.lightGreen[500],
                                padding: EdgeInsets.all(0),
                              ),
                            ActionChip(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              label: Text('...', style: TextStyle(fontSize: 10),),
                              backgroundColor: Colors.lightGreen[500],
                              padding: EdgeInsets.all(0),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Tags:', textAlign: TextAlign.center,),
                                      content: Wrap(
                                        children: [
                                          for (var t in dishes[i].tags)
                                            Chip(
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              label: Text('#$t', style: TextStyle(fontSize: 10),),
                                              backgroundColor: Colors.lightGreen[500],
                                              padding: EdgeInsets.all(0),
                                            ),
                                        ],
                                      ),
                                    );
                                  }
                                );
                              },
                            )
                          ] 
                        : [
                        for (var t in dishes[i].tags)
                            Chip(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              label: Text('#$t', style: TextStyle(fontSize: 10),),
                              backgroundColor: Colors.lightGreen[500],
                              padding: EdgeInsets.all(0),
                          ),
                        ]
                    ), // tags
                    Spacer(),
                    Row(
                      spacing: 2,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(.0),
                            foregroundColor: Colors.white, // background color
                            backgroundColor: Colors.green, // text color
                            side: BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context){
                              return Scaffold(
                                appBar: AppBar(
                                  title: Text('Edit Dish'),
                                  backgroundColor: const Color.fromARGB(255, 114, 189, 108),
                                ),
                                body: DishForm(dishId: dishes[i].id)
                              );
                              }),
                            );
                            setState(() {
                              dishes.clear();
                            });
                          },
                          child: Text('Edit'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, // background color
                            backgroundColor: Colors.red, // text color
                            side: BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Please Confirm'),
                                  content: Text("Do you want to delete '${dishes[i].name}' completely?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          dbHelper.deleteDish(dishes[i].id!);
                                        });
                                      },
                                      child: const Text('Yes')),
                                    TextButton(
                                      onPressed: () {
                                        // Close the dialog
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('No')),
                                  ],  
                                );
                            });
                          },
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ]
                )
              ),
            ],
          ),



        );
      }
    );
  }
}

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
    List<Ingredient> prodTrue = [];
    List<Ingredient> prodFalse = [];
    List<String> tempDishes = [];
    String value = await readShopList(widget.fileName);
    var data = json.decode(value);
    for(var dish in data['dishes']){
      tempDishes.add(dish);
    }

    for(var ing in data['products']){
      Ingredient prod = Ingredient(
        name: ing['name'] as String,
        quantity: ing['quantity'],
        unit: ing['unit'] as String,
        checked: ing['checked'] == 1 ? true : false,
      );
      if (prod.checked){
        prodTrue.add(prod);
      } else {
        prodFalse.add(prod);
      }
    }
    setState(() {
      products = List.from(prodFalse)..addAll(prodTrue);
      dishes = tempDishes;
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

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyIngs = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController recipeController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  List<Ingredient> ingredients = <Ingredient>[];
  
  // for add ingredients form
  TextEditingController newIngredientNameController = TextEditingController();
  TextEditingController newIngredientQuantityController = TextEditingController();
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
      newIngredientQuantityController.text = '1';
      // extend ingredients with dish ingredients if dish is not null
      List<Ingredient> tempIngredients = dish?.ingredients ?? <Ingredient>[];
      ingredients = List.from(tempIngredients)..addAll(ingredients);
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

    return Padding(
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
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_enhance_outlined, color: Colors.green,),
                    onPressed: ()async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                      if (image == null) return;
                      final InputImage inputImage = InputImage.fromFilePath(image.path);
                      final RecognizedText recognisedText = await textRecognizer.processImage(inputImage);
                      String text = '';
                      for (TextBlock block in recognisedText.blocks) {
                        for (TextLine line in block.lines) {
                          for (TextElement element in line.elements) {
                            text += "${element.text} ";
                          }
                        }
                      }
                      setState(() {
                        recipeController.text = text;
                      });
                    },
                    alignment: Alignment.centerLeft,
                  ),
                  Text("Scan recept via camera or from Image", style: TextStyle(fontSize: 14, color: Colors.green),),
                ],
              ),
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
              Text('Add Ingredients:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              SizedBox(height: 10,),
          //  add ingerdient part
              Form(
                key: _formKeyIngs,
                child: Column(
                  children: [
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
                    child: Row(
                        spacing: 4,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: newIngredientQuantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 3, color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              // Set border for focused state
                              focusedBorder: OutlineInputBorder(
                                borderSide:  BorderSide(width: 3, color: Colors.green),
                                borderRadius: BorderRadius.circular(4),
                              )

                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Quantity is required';
                                }
                                if (double.tryParse(value) == null && int.tryParse(value) == null){
                                  return 'Provide a number';
                                }
                                if (double.tryParse(value)! <= 0 && int.tryParse(value)! <= 0){
                                  return 'Should be positive';
                                }
                                return null;
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
                          ElevatedButton(
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
                                if (_formKeyIngs.currentState!.validate()){
                                  ingredients.add(Ingredient(
                                    name: newIngredientNameController.text,
                                    quantity: int.tryParse(newIngredientQuantityController.text) ?? double.tryParse(newIngredientQuantityController.text)!,
                                    unit: newIngredientUnitControler.text,
                                  ));
                                newIngredientNameController.clear();
                                newIngredientQuantityController.text = '1';
                                newIngredientUnitControler.text = 'g';
                                }
                              });
                            },
                            child: Text(
                              "Add",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
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
                Text(ingredient.toString(), style: TextStyle(fontSize: 16),),
              ],
            ),

          // ----------------------
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // background color
              backgroundColor: Colors.orange, // text color
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final dish = Dish(
                  id: widget.dishId,
                  name: nameController.text,
                  mealType: dropdownValue!,
                  recipe: recipeController.text,
                  tags: tagsController.text.split(',').map((e) => e.trim()).toList(),
                  ingredients: ingredients,
                );
                String message = 'Dish saved!';
                if (widget.dishId != null){
                  final id = await dbHelper.updateDish(dish);
                  if (id == 0) {
                    message = 'Dish not found!';
                  }
                  if (context.mounted){Navigator.of(context).pop(widget.dishId);}
                } else {
                    final id = await dbHelper.insertDish(dish);
                    if (id == 0) {
                      message = 'Something went wrong!';
                    }
                }
                setState(() {
                
                  // clean up the form
                  nameController.clear();
                  recipeController.clear();
                  tagsController.clear();
                  ingredients.clear();
                  newIngredientNameController.clear();
                  newIngredientQuantityController.text = '1';
                  newIngredientUnitControler.text = 'g';
                  // show upd success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                });
              }
            },
            child: Text(
              "Save Dish",
              style: TextStyle(fontSize: 20),
            ),
          ),
          // ----------------------
        ],
      ), 
    ),
    );
  }
}