// lib/screens/meal_types_screen.dart

import 'package:flutter/material.dart';
import '../models/meal_type.dart';
import '../services/meal_type_service.dart';
import 'meal_type_form_screen.dart';

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
    _load();
  }

  void _load() {
    _mealTypesFuture = _service.loadMealTypes();
  }

  Future<void> _navigateToForm([MealType? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealTypeFormScreen(existing: existing),
      ),
    );
    setState(_load);
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
                    'Carbs: ${mt.carbs.toStringAsFixed(2)}g • '
                    'Protein: ${mt.protein.toStringAsFixed(2)}g • '
                    'Fat: ${mt.fat.toStringAsFixed(2)}g',
                  ),
                  onTap: () => _navigateToForm(mt),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
