import 'dart:convert';


// Ingredient class
class Ingredient{
    String name;
    num quantity;
    String unit;
    bool checked;
    
    Ingredient({required this.name, required this.quantity, required this.unit, this.checked = false});

    // Convert to a map
    Map<String, dynamic> toMap(){
        return {
            'name': name,
            'quantity': quantity,
            'unit': unit,
            'checked': checked ? 1 : 0
        };
    }

    @override
    String toString(){
        return '$name - $quantity ($unit)';
    }


    Ingredient operator +(Ingredient other){
        if (name == other.name && unit == other.unit){
            return Ingredient(
              name: name,
              quantity: quantity + other.quantity,
              unit: unit,
            );
        }
        return this;
    }

    Ingredient operator *(int multiplier){
        return Ingredient(
            name: name,
            quantity: quantity * multiplier,
            unit: unit,
        );
    }

}

class Dish{
    Dish({this.id, required this.name, required this.mealType, required this.recipe, this.tags = const [], required this.ingredients});
    int? id;
    final String name;
    final String mealType;
    final String recipe;
    final List<String> tags;
    final List<Ingredient> ingredients;

  @override
  toString() {
    return 'Dish $id: $name';
  }

// Convert the class into a Map. The key must corrspond to the names of the columns in the DB
    Map<String, dynamic> toMap(){
        return {
            'name': name,
            'mealType': mealType,
            'recipe': recipe,
            'tags': jsonEncode(tags),
            'ingredients': jsonEncode(ingredients.map((ing) => ing.toMap()).toList())
        };
    }

    factory Dish.fromMap(Map<String, dynamic> map){
        return Dish(
            id: map['id'],
            name: map['name'],
            mealType: map['mealType'],
            recipe: map['recipe'],
            tags: jsonDecode(map['tags']),
            ingredients: jsonDecode(map['ingredients']),
        );
    }

}
