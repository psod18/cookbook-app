// import 'package:cookery_book/utils/db_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:cookery_book/models/data.dart'; 


// class DishCard extends StatefulWidget {
//   DishCard({required this.dish, required this.cardIndex, required this.cardsTotal});
//   final Dish dish;
//   final int cardIndex;
//   final int cardsTotal;

// @override
// State<StatefulWidget> createState() => _DishCardState();

// }


// class _DishCardState extends State<DishCard> {

//   final dbHelper = DatabaseHelper();
//   List<int> menuIdxs = [];

//   Color mealTypeColor(String mealType){
//     switch(mealType){
//       case 'breakfast':
//         return Colors.orange;
//       case 'lunch':
//         return Colors.green;
//       case 'dinner':
//         return Colors.red;
//         case 'dessert':
//         return Colors.purple;
//       default:
//         return Colors.black;
//     }
//   }

//     @override
//   void initState() {
//     super.initState();
//     loadMenuIdxs();
//     }


//   void loadMenuIdxs () async {
//     final data = await dbHelper.menuIds();
//     setState(() {
//       menuIdxs = data;
//     });
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: mealTypeColor(widget.dish.mealType), width: 8.0),
//         color: Color.fromARGB(255, 243, 213, 148),
//         borderRadius: BorderRadius.all(Radius.circular(12.0)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade400,
//             spreadRadius: 5,
//             blurRadius: 7,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       margin: EdgeInsets.all(12),
//       height: 450,
//       width: 300,
//       child: Scaffold(
//         floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
//         floatingActionButton:  FloatingActionButton.small(
//           onPressed: (){
//             setState(() {
//                 // add or remove to menu table in db
//                 menuIdxs.contains(widget.dish.id) ? {menuIdxs.remove(widget.dish.id), dbHelper.deleteMenu(widget.dish.id) }: {menuIdxs.add(widget.dish.id), dbHelper.insertMenu(widget.dish.id, 1)};                
//             });
//           },
//           backgroundColor: menuIdxs.contains(widget.dish.id)  ? Colors.green : const Color.fromARGB(255, 245, 175, 175),
//           child: menuIdxs.contains(widget.dish.id) ? Icon(Icons.done) : Icon(Icons.add),
//         ),
//       body:        
//         Column(
//           children: <Widget>[
//             Align(
//               alignment: Alignment.topLeft,
//               child: 
//               Padding(
//                 padding: EdgeInsets.all(8.0),
//                 child: Text('${widget.cardIndex} / ${widget.cardsTotal}',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 20.0,
//             ),
//             Align(
//               alignment: Alignment.center,
//               child:Center(
//                 child: TextButton(
//                   onPressed: (){
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: Text(widget.dish.name),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: <Widget>[
//                               Text("How to cook:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
//                               Text(widget.dish.recipe, textAlign: TextAlign.justify, style: TextStyle(fontSize: 16),),
//                               SizedBox(height: 15.0,),
//                               Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
//                               for (var i in widget.dish.ingredients)
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Text(i.toString(), style: TextStyle(fontStyle: FontStyle.italic),),
//                                     ),
//                                   ],
//                                 ),
//                             ],
//                           ),
//                           actions: <Widget>[
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).pop();
//                               },
//                               child: Text('Close'),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                   child: Text(
//                     widget.dish.name,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 24.0,
//                     ),
//                   )

//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 150.0,
//             ),
//             Align(
//               alignment: Alignment.center,
//               child: Text(
//                 widget.dish.mealType,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20.0,
//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 20.0,
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   for(var t in widget.dish.tags)
//                       Chip(
//                         label: Text(t),
//                         backgroundColor: Colors.lightGreen[500],
//                       ),
//                 ],
//               )
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }