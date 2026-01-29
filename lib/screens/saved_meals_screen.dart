// lib/screens/saved_meals_screen.dart
//
// Simple library: list meals, search by name, toggle ★ favourite,
// delete meal, view read-only details.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../utils/responsive_utils.dart';

class SavedMealsScreen extends StatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  final _service = MealService();
  late Future<List<Meal>> _futureMeals;
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtl.addListener(() => setState(() {}));
  }

  void _load() => _futureMeals = _service.loadMeals();

  Future<void> _toggleFav(String id) async {
    await _service.toggleFavorite(id);
    _load();
    setState(() {});
  }

  Future<void> _delete(String id) async {
    await _service.deleteMeal(id);
    _load();
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Meals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                labelText: 'Search meals',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Meal>>(
              future: _futureMeals,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final meals = snap.data!;
                final query = _searchCtl.text.toLowerCase();
                final list = meals
                    .where((m) => m.name.toLowerCase().contains(query))
                    .toList()
                  ..sort((a, b) {
                    // Favorites first, then by date (newest first)
                    if (a.favorite && !b.favorite) return -1;
                    if (!a.favorite && b.favorite) return 1;
                    return b.createdAt.compareTo(a.createdAt);
                  });

                if (list.isEmpty) {
                  return const Center(child: Text('No meals found.'));
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final meal = list[i];
                    return ListTile(
                      title: Text(meal.name),
                      subtitle: Text(
                        '${meal.createdAt.toLocal().toString().split(".").first}'
                        ' • ${meal.rows.length} items',
                      ),
                      leading: IconButton(
                        icon: Icon(
                          meal.favorite
                              ? Icons.star
                              : Icons.star_border_outlined,
                          color: meal.favorite ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () => _toggleFav(meal.id),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editMeal(meal);
                          } else if (value == 'delete') {
                            _delete(meal.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showDetails(context, meal),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editMeal(Meal meal) async {
    await context.push('/create', extra: meal);
    _load();
    setState(() {});
  }

  // simple read-only dialog
  void _showDetails(BuildContext ctx, Meal meal) {
    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(meal.name),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.dialogWidth(ctx),
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: SizedBox(
            width: ResponsiveUtils.dialogWidth(ctx),
            child: ListView(
              shrinkWrap: true,
              children: meal.rows.map((mi) {
                return ListTile(
                  dense: true,
                  title: Text(mi.ingredient.name),
                  trailing: Text('${mi.weight.toStringAsFixed(1)} g'),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
