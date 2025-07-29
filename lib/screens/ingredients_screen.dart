// lib/screens/ingredients_screen.dart

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final _service = IngredientService();
  late Future<List<Ingredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _ingredientsFuture = _service.loadIngredients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: FutureBuilder<List<Ingredient>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final ingredients = snapshot.data!;
            if (ingredients.isEmpty) {
              return const Center(child: Text('No ingredients found.'));
            }
            return ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                return ListTile(
                  title: Text(ing.name),
                  subtitle: Text(
                    'Default Weight: ${ing.defaultWeight.toStringAsFixed(2)}g • '
                    'Calories: ${ing.calories.toStringAsFixed(2)} • '
                    'Carbs: ${ing.carbs.toStringAsFixed(2)}g • '
                    'Protein: ${ing.protein.toStringAsFixed(2)}g • '
                    'Fat: ${ing.fat.toStringAsFixed(2)}g',
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
