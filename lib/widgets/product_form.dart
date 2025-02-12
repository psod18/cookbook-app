
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Add Product to bin',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
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
            decoration: const InputDecoration(
              labelText: "Product name",
              icon: Icon(Icons.post_add),
            ),
            onChanged: (value) => newProduct['name'] = value,
          ),
          TextFormField(
              decoration: const InputDecoration(
                labelText: "Quantity",
                icon: Icon(Icons.shopping_bag),
              ),
              onChanged: (value) => newProduct['quantity'] = int.parse(value),
          ),
          ListTile(
            title: const Text("Unit"),
            trailing: DropdownButton<String>(
              value: 'kg',
              onChanged: (String? value) {
                setState(() {
                  newProduct['unit'] = value;
                });
              },
              items: <String>['kg', 'g', 'l', 'ml', 'pcs']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            child: const Text("Add Product"),
            onPressed: () {
              Navigator.of(context).pop(newProduct);
            },
          ),
        ],
      ),
    );
  }
}
