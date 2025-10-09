// lib/screens/ingredient_form_screen.dart

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? existing;
  const IngredientFormScreen({super.key, this.existing});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _carbsController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  final _service = IngredientService();

  @override
  void initState() {
    super.initState();
    final i = widget.existing;
    _nameController = TextEditingController(text: i?.name ?? '');
    _weightController = TextEditingController(
      text: i?.defaultWeight.toString() ?? '',
    );
    _caloriesController = TextEditingController(
      text: i?.calories.toString() ?? '',
    );
    _carbsController = TextEditingController(text: i?.carbs.toString() ?? '');
    _proteinController = TextEditingController(
      text: i?.protein.toString() ?? '',
    );
    _fatController = TextEditingController(text: i?.fat.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final ingredient = Ingredient(
      id: id,
      name: _nameController.text.trim(),
      defaultWeight: double.parse(_weightController.text),
      calories: double.parse(_caloriesController.text),
      carbs: double.parse(_carbsController.text),
      protein: double.parse(_proteinController.text),
      fat: double.parse(_fatController.text),
    );

    await _service.upsertIngredient(ingredient);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing != null) {
      await _service.deleteIngredient(widget.existing!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Ingredient' : 'Add Ingredient'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Ingredient'),
                    content: const Text(
                      'Are you sure you want to delete this ingredient?',
                    ),
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
                  await _delete();
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Default Weight (g)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Invalid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Invalid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Invalid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Invalid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(labelText: 'Fat (g)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? 'Invalid'
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
