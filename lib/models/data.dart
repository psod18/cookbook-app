import 'dart:convert';


// Ingredient class
class Ingredient{
    Ingredient({required this.name, required this.quantity, required this.unit});
    final String name;
    num quantity;
    final String unit;

    // Convert to a map
    Map<String, dynamic> toMap(){
        return {
            'name': name,
            'quantity': quantity,
            'unit': unit,
        };
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
    Dish({required this.id, required this.name, required this.mealType, required this.recipe, this.tags = const [], required this.ingredients});
    final int id;
    final String name;
    final String mealType;
    final String recipe;
    final List<String> tags;
    final List<Ingredient> ingredients;


// Convert the class into a Map. The key must corrspond to the names of the columns in the DB
    Map<String, dynamic> toMap(){
        return {
            'id': id,
            'name': name,
            'mealType': mealType,
            'recipe': recipe,
            'tags': jsonEncode(tags),
            'ingredients': jsonEncode(ingredients.map((ing) => ing.toMap()).toList())
        };
    }

}
