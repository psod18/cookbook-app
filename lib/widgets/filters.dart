
import 'package:flutter/material.dart';

// Create Singleton class to store the filter state
class FilterState {
  static final FilterState _instance = FilterState._internal();
  factory FilterState() => _instance;
  FilterState._internal();

  Map<String, bool> mealTypeFilter = {
    'breakfast': true,
    'lunch': true,
    'dinner': true,
    'dessert': true,
  };
  String filterQuery = '';

  bool switchValue = true;

  void setFiltersFalse() {
    mealTypeFilter.updateAll((key, value) => value = false);
  }

  void setFiltersTrue() {
    mealTypeFilter.updateAll((key, value) => value = true);
  }

  setFilterQuery(String query) {
    filterQuery = query;
  }

}

class SetFilterDialog extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => _SetFilterDialog();
}

class _SetFilterDialog extends State<SetFilterDialog>  {
  
  FilterState filterState = FilterState();

  @override
  Widget build(BuildContext context) {
    var _controller = TextEditingController(text: filterState.filterQuery);
    
  
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      child: Container(
        margin: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 8, bottom: 20),
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
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Query text',
                suffixIcon: IconButton(
                  onPressed: _controller.clear,
                  icon: Icon(Icons.clear),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 3, color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:  BorderSide(width: 3, color: Colors.orange),
                  borderRadius: BorderRadius.circular(15),
                )
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select/Deselect All',style: TextStyle(fontWeight: FontWeight.bold),),
                Switch(
                  value: filterState.switchValue,
                  onChanged: (bool value){
                  setState(() {
                    filterState.switchValue = value;
                    value ? filterState.setFiltersTrue() : filterState.setFiltersFalse();
                  });
                })
              ],
            ),
            Divider(
                  color: Colors.black,
                ),
            // Meal type filter
            for (var mealType in filterState.mealTypeFilter.keys)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(mealType),
                  Checkbox(
                    value: filterState.mealTypeFilter[mealType],
                    onChanged: (value) {
                      setState(() {
                        filterState.mealTypeFilter[mealType] = value!;
                      });
                    },
                  ),
                ],
              ),
            ElevatedButton(
              child: const Text("Ok"),
              onPressed: () {
                filterState.setFilterQuery(_controller.text);
              Navigator.of(context).pop(filterState);
          },
          ),
          ],
        ),
      ),
    );
  }
}