// lib/screens/meal_types_screen.dart

import 'package:flutter/material.dart';
import '../models/meal_type.dart';
import '../services/meal_type_service.dart';

class MealTypesScreen extends StatefulWidget {
  const MealTypesScreen({super.key});

  @override
  State<MealTypesScreen> createState() => _MealTypesScreenState();
}

class _MealTypesScreenState extends State<MealTypesScreen> {
  final _service = MealTypeService();
  late Future<List<MealType>> _mealTypesFuture;

  @override
  void initState() {
    super.initState();
    _mealTypesFuture = _service.loadMealTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Types')),
      body: FutureBuilder<List<MealType>>(
        future: _mealTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final mealTypes = snapshot.data!;
            if (mealTypes.isEmpty) {
              return const Center(child: Text('No meal types found.'));
            }
            return ListView.builder(
              itemCount: mealTypes.length,
              itemBuilder: (context, index) {
                final mt = mealTypes[index];
                return ListTile(
                  title: Text(mt.name),
                  subtitle: Text(
                    'Calories: ${mt.calories}, '
                    'Carbs: ${mt.carbs}g • '
                    'Protein: ${mt.protein}g • '
                    'Fat: ${mt.fat}g',
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
