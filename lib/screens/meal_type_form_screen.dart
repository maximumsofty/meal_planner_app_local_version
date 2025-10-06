// lib/screens/meal_type_form_screen.dart

import 'package:flutter/material.dart';
import '../models/meal_type.dart';
import '../services/meal_type_service.dart';

class MealTypeFormScreen extends StatefulWidget {
  final MealType? existing;
  const MealTypeFormScreen({super.key, this.existing});

  @override
  State<MealTypeFormScreen> createState() => _MealTypeFormScreenState();
}

class _MealTypeFormScreenState extends State<MealTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _carbsController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  final _service = MealTypeService();

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameController = TextEditingController(text: m?.name ?? '');
    _carbsController =
        TextEditingController(text: m?.carbs.toString() ?? '');
    _proteinController =
        TextEditingController(text: m?.protein.toString() ?? '');
    _fatController = TextEditingController(text: m?.fat.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.existing?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final newMealType = MealType(
      id: id,
      name: _nameController.text.trim(),
      carbs: double.parse(_carbsController.text),
      protein: double.parse(_proteinController.text),
      fat: double.parse(_fatController.text),
    );

    await _service.upsertMealType(newMealType);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meal Type' : 'Add Meal Type'),
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
                controller: _carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(labelText: 'Fat (g)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
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
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
