// lib/screens/create_meal_screen.dart
//
// STEP 19: user picks a Meal Type first.
// • Dropdown lists stored MealTypes (carb / protein / fat targets)
// • Running “target minus current” bar shows grams still available.
// Next steps will build on this (editable % fields, locking, etc.).

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';
import '../models/meal_type.dart';
import '../services/ingredient_service.dart';
import '../services/meal_type_service.dart';

class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key});

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  // Services ---------------------------------------------------------------
  final _ingredientService = IngredientService();
  final _mealTypeService = MealTypeService();

  // Data that loads once ----------------------------------------------------
  late Future<List<Ingredient>> _allIngredientsFuture;
  late Future<List<MealType>> _allMealTypesFuture;

  // User selections ---------------------------------------------------------
  MealType? _selectedMealType;
  final List<MealIngredient> _mealIngredients = [];

  // ------------------------------------------------------------------------
  // LIFE-CYCLE
  // ------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _allIngredientsFuture = _ingredientService.loadIngredients();
    _allMealTypesFuture   = _mealTypeService.loadMealTypes();
  }

  // ------------------------------------------------------------------------
  // CALCULATIONS
  // ------------------------------------------------------------------------
  double get _totalCarbs   =>
      _mealIngredients.fold(0, (sum, mi) => sum + mi.carbs);
  double get _totalProtein =>
      _mealIngredients.fold(0, (sum, mi) => sum + mi.protein);
  double get _totalFat     =>
      _mealIngredients.fold(0, (sum, mi) => sum + mi.fat);

  // Remaining (target – current); if no target selected → null
  double? get _remainingCarbs   =>
      _selectedMealType == null ? null : _selectedMealType!.carbs   - _totalCarbs;
  double? get _remainingProtein =>
      _selectedMealType == null ? null : _selectedMealType!.protein - _totalProtein;
  double? get _remainingFat     =>
      _selectedMealType == null ? null : _selectedMealType!.fat     - _totalFat;

  // ------------------------------------------------------------------------
  // MUTATION HELPERS
  // ------------------------------------------------------------------------
  void _addIngredient(Ingredient ing) =>
      setState(() => _mealIngredients
          .add(MealIngredient(ingredient: ing, weight: ing.defaultWeight)));

  void _removeIngredient(int index) =>
      setState(() => _mealIngredients.removeAt(index));

  void _updateWeight(int index, String value) {
    final w = double.tryParse(value);
    if (w == null) return;
    setState(() => _mealIngredients[index].weight = w);
  }

  // ------------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Builder')),
      body: FutureBuilder(
        // Wait for BOTH ingredients & meal types
        future: Future.wait([
          _allIngredientsFuture,
          _allMealTypesFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Unpack data
          final ingredients = snapshot.data![0] as List<Ingredient>;
          final mealTypes   = snapshot.data![1] as List<MealType>;

          // -------------------------------------------------------------- //
          return Column(
            children: [
              // ************************************************************
              // (1) MEAL-TYPE DROPDOWN
              // ************************************************************
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DropdownButtonFormField<MealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type (pick to set macro targets)',
                    border: OutlineInputBorder(),
                  ),
                  items: mealTypes
                      .map((mt) => DropdownMenuItem(
                            value: mt,
                            child: Text(mt.name),
                          ))
                      .toList(),
                  onChanged: (mt) => setState(() {
                    _selectedMealType = mt;
                    // Clear existing ingredients when changing MT
                    _mealIngredients.clear();
                  }),
                ),
              ),

              // ************************************************************
              // (2) REMAINING-MACRO BAR (only after pick)
              // ************************************************************
              if (_selectedMealType != null)
                Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Carbs: ${_totalCarbs.toStringAsFixed(1)} / ${_selectedMealType!.carbs} '
                        '(${_remainingCarbs!.toStringAsFixed(1)}g left)',
                      ),
                      Text(
                        'Protein: ${_totalProtein.toStringAsFixed(1)} / ${_selectedMealType!.protein} '
                        '(${_remainingProtein!.toStringAsFixed(1)}g left)',
                      ),
                      Text(
                        'Fat: ${_totalFat.toStringAsFixed(1)} / ${_selectedMealType!.fat} '
                        '(${_remainingFat!.toStringAsFixed(1)}g left)',
                      ),
                    ],
                  ),
                ),

              const Divider(height: 0),

              // ************************************************************
              // (3) SEARCH-&-ADD ONLY WHEN MEAL TYPE CHOSEN
              // ************************************************************
              if (_selectedMealType != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Autocomplete<Ingredient>(
                    optionsBuilder: (TextEditingValue text) {
                      if (text.text.isEmpty) return const Iterable.empty();
                      return ingredients.where((ing) => ing.name
                          .toLowerCase()
                          .contains(text.text.toLowerCase()));
                    },
                    displayStringForOption: (ing) => ing.name,
                    fieldViewBuilder:
                        (ctx, controller, focus, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focus,
                        decoration: const InputDecoration(
                          labelText: 'Add Ingredient',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    onSelected: (ing) => _addIngredient(ing),
                  ),
                ),

              // ************************************************************
              // (4) INGREDIENT LIST
              // ************************************************************
              Expanded(
                child: _mealIngredients.isEmpty
                    ? const Center(child: Text('No ingredients added yet.'))
                    : ListView.separated(
                        itemCount: _mealIngredients.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final mi = _mealIngredients[index];
                          return ListTile(
                            title: Text(mi.ingredient.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Weight (g): '),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: TextEditingController(
                                            text: mi.weight
                                                .toStringAsFixed(2)),
                                        keyboardType:
                                            const TextInputType
                                                .numberWithOptions(
                                                    decimal: true),
                                        onSubmitted: (val) =>
                                            _updateWeight(index, val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                        'Cal ${mi.calories.toStringAsFixed(1)}'),
                                  ],
                                ),
                                // --- Macro lines + % of target -------------
                                if (_selectedMealType != null)
                                  Text(
                                    'C ${mi.carbs.toStringAsFixed(1)}g '
                                    '(${(mi.carbs / _selectedMealType!.carbs * 100).toStringAsFixed(1)}%) '
                                    '• P ${mi.protein.toStringAsFixed(1)}g '
                                    '(${(mi.protein / _selectedMealType!.protein * 100).toStringAsFixed(1)}%) '
                                    '• F ${mi.fat.toStringAsFixed(1)}g '
                                    '(${(mi.fat / _selectedMealType!.fat * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeIngredient(index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
