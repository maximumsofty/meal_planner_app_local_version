// lib/screens/ingredients_screen.dart

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import 'ingredient_form_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final _service = IngredientService();
  late Future<List<Ingredient>> _ingredientsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _load(); // initialize the future so FutureBuilder has a value
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    _ingredientsFuture = _service.loadIngredients();
  }

  Future<void> _navigateToForm([Ingredient? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientFormScreen(existing: existing),
      ),
    );
    setState(_load);
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset ingredients?'),
        content: const Text(
          'This will replace your current ingredients with the built-in defaults. '
          'This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _service.resetToDefaults();

    if (!mounted) return;
    setState(() {
      _ingredientsFuture = _service.loadIngredients();
      _searchController.clear();
      _searchQuery = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingredients reset to defaults')),
    );
  }

  Future<void> _confirmDelete(Ingredient ing) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete "${ing.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteIngredient(ing.id);
      setState(_load);
    }
  }

  List<Ingredient> _filter(List<Ingredient> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((i) => i.name.toLowerCase().contains(q)).toList();
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
          }

          final ingredients = snapshot.data ?? const <Ingredient>[];
          final displayList = _filter(ingredients);

          if (ingredients.isEmpty) {
            return const Center(child: Text('No ingredients found.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Ingredients',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to defaults'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: displayList.isEmpty
                    ? const Center(child: Text('No matches for your search.'))
                    : ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final ing = displayList[index];
                          return ListTile(
                            title: Text(ing.name),
                            subtitle: Text(
                              'Default: ${ing.defaultWeight.toStringAsFixed(2)} g • '
                              'Cal: ${ing.calories.toStringAsFixed(2)} • '
                              'Carb: ${ing.carbs.toStringAsFixed(2)} g • '
                              'Prot: ${ing.protein.toStringAsFixed(2)} g • '
                              'Fat: ${ing.fat.toStringAsFixed(2)} g',
                            ),
                            onTap: () => _navigateToForm(ing),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDelete(ing),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
