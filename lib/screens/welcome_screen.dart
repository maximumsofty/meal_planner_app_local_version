// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';

// import the screens you want to navigate to
import 'ingredients_screen.dart';
import 'meal_types_screen.dart';
import 'create_meal_screen.dart';
import 'saved_meals_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // helper to avoid repeating boilerplate
    ElevatedButton navButton(String label, Widget screen) =>
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Planner')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome! Choose where to start:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            navButton('Create Meal', const CreateMealScreen()),
            navButton('Saved Meals', const SavedMealsScreen()), // NEW
            navButton('Ingredients', const IngredientsScreen()),
            navButton('Meal Types', const MealTypesScreen()),
          ],
        ),
      ),
    );
  }
}
