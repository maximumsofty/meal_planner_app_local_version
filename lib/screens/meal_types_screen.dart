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
  List<MealType> _mealTypes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _mealTypesFuture = _service.loadMealTypes().then((types) {
      _mealTypes = List.of(types);
      return _mealTypes;
    });
  }

  Future<void> _navigateToForm([MealType? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealTypeFormScreen(existing: existing)),
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
            final mealTypes = _mealTypes;
            if (mealTypes.isEmpty) {
              return const Center(child: Text('No meal types found.'));
            }
            return ReorderableListView.builder(
              itemCount: mealTypes.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _mealTypes.removeAt(oldIndex);
                  _mealTypes.insert(newIndex, item);
                });
                _service.saveMealTypes(_mealTypes);
              },
              itemBuilder: (context, index) {
                final mt = mealTypes[index];
                final ratio = _ratioText(mt);
                return ListTile(
                  key: ValueKey(mt.id),
                  title: Text('${mt.name}  ($ratio)'),
                  subtitle: Text(
                    'Carbs: ${mt.carbs.toStringAsFixed(2)}g • '
                    'Protein: ${mt.protein.toStringAsFixed(2)}g • '
                    'Fat: ${mt.fat.toStringAsFixed(2)}g',
                  ),
                  trailing: const Icon(Icons.drag_handle),
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

  String _ratioText(MealType mt) =>
      _formatFatRatio(mt.fat, mt.carbs, mt.protein);

  String _formatFatRatio(double fat, double carbs, double protein) {
    final sum = carbs + protein;
    if (sum <= 0) {
      if (fat <= 0) return '0:1';
      return 'inf:1';
    }

    final ratio = fat / sum;
    return '${_trimmedNumber(ratio)}:1';
  }

  String _trimmedNumber(double value) {
    final asFixed2 = value.toStringAsFixed(2);
    if (asFixed2.endsWith('.00')) return value.toStringAsFixed(0);
    if (asFixed2.endsWith('0')) return value.toStringAsFixed(1);
    return asFixed2;
  }
}
