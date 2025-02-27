
import 'package:flutter/material.dart';

// Create Singleton class to store the filter state
// class FilterState {
//   static final FilterState _instance = FilterState._internal();
//   factory FilterState() => _instance;
//   FilterState._internal();

//   Map<String, bool> mealTypeFilter = {
//     'breakfast': false,
//     'lunch': false,
//     'dinner': false,
//     'snack': false,
//   };
//   String filterQuery = '';
// }

class SetFilterDialog extends StatefulWidget{
  SetFilterDialog({required this.mealTypeFilter, required this.filterQuery});

  Map<String, bool> mealTypeFilter;
  String filterQuery;

  @override
  State<StatefulWidget> createState() => _SetFilterDialog();
}

class _SetFilterDialog extends State<SetFilterDialog>  {
  @override
  Widget build(BuildContext context) {
    var _controller = TextEditingController(text: widget.filterQuery);
  
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      child: Container(
        margin: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'filter by name',
                 suffixIcon: IconButton(
                  onPressed: _controller.clear,
                  icon: Icon(Icons.clear),
                ),
              ),
            ),
            // Meal type filter
            for (var mealType in widget.mealTypeFilter.keys)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(mealType),
                  Checkbox(
                    value: widget.mealTypeFilter[mealType],
                    onChanged: (value) {
                      setState(() {
                        widget.mealTypeFilter[mealType] = value!;
                      });
                    },
                  ),
                ],
              ),
            ElevatedButton(
              child: const Text("Ok"),
              onPressed: () {
              Navigator.of(context).pop(_controller.text);
          },
          ),
          ],
        ),
      ),
    );
  }
}