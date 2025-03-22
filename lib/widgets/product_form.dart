
import 'package:flutter/material.dart';


class AddProduct extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  Map<String, dynamic> newProduct = {
    'name': '',
    'quantity': 0,
    'unit': '',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
        spacing: 6,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Product to bin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              Container(
                margin: const EdgeInsets.only(top: 18, right: 18, bottom: 10),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.orange),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 15.0,
                    ),
                  ),
                ),
              ),
            ]
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: "Product name",
              icon: Icon(Icons.post_add),
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
            onChanged: (value) => newProduct['name'] = value,
          ),
          TextFormField(
              decoration: InputDecoration(
                labelText: "Quantity",
                icon: Icon(Icons.shopping_bag),
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
            onChanged: (value) => newProduct['quantity'] = int.parse(value),
          ),
          Row(
            children: [
            const Icon(Icons.production_quantity_limits_outlined),
            SizedBox(width: 16,),
            const Text("Unit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
            Spacer(),
             DropdownButton<String>(
              value: 'g',
              onChanged: (String? value) {
                setState(() {
                  newProduct['unit'] = value;
                });
              },
              items: <String>['g', 'ml', 'unit']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ]
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(8),
                            foregroundColor: Colors.white, // background color
                            backgroundColor: Colors.green, // text color
                            side: BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
            child: const Text("Add Product"),
            onPressed: () {
              Navigator.of(context).pop(newProduct);
            },
          ),
        ],
      ),
      ),
    );
  }
}
