// lib/screens/create_meal_screen.dart
//
// STEP 20  –  each ingredient row is its own mini-widget that
// • keeps TextEditingControllers alive
// • lets user edit weight _or_ any macro %
// • notifies parent so totals & other % rows refresh

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
  // ───────────────────  services & one-time loads  ──────────────────────
  final _ingredientService = IngredientService();
  final _mealTypeService   = MealTypeService();

  late Future<List<Ingredient>> _allIngredientsFuture;
  late Future<List<MealType>>   _allMealTypesFuture;

  // ───────────────────  user selections  ────────────────────────────────
  MealType? _selectedMealType;
  final List<MealIngredient> _mealIngredients = [];

  // ───────────────────  life-cycle  ─────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _allIngredientsFuture = _ingredientService.loadIngredients();
    _allMealTypesFuture   = _mealTypeService.loadMealTypes();
  }

  // ───────────────────  aggregate helpers  ──────────────────────────────
  double get _totalCarbs   =>
      _mealIngredients.fold(0, (s, mi) => s + mi.carbs);
  double get _totalProtein =>
      _mealIngredients.fold(0, (s, mi) => s + mi.protein);
  double get _totalFat     =>
      _mealIngredients.fold(0, (s, mi) => s + mi.fat);

  double? _remaining(double? tgt, double used) =>
      tgt == null ? null : tgt - used;

  // whenever a row changes weight → refresh totals & % bars
  void _onRowUpdated() => setState(() {});

  // ───────────────────  mutators  ───────────────────────────────────────
  void _addIngredient(Ingredient ing) {
    setState(() {
      _mealIngredients
          .add(MealIngredient(ingredient: ing, weight: ing.defaultWeight));
    });
  }

  void _removeIngredient(int index) =>
      setState(() => _mealIngredients.removeAt(index));

  // ───────────────────  UI  ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Builder')),
      body: FutureBuilder(
        future: Future.wait([_allIngredientsFuture, _allMealTypesFuture]),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final ingredients = snap.data![0] as List<Ingredient>;
          final mealTypes   = snap.data![1] as List<MealType>;

          // ────────────────────────────────────────────────────────────
          return Column(
            children: [
              // 1️⃣  pick Meal Type
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DropdownButtonFormField<MealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type (sets macro targets)',
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
                    _mealIngredients.clear();
                  }),
                ),
              ),

              // 2️⃣  remaining grams bar
              if (_selectedMealType != null)
                Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _remainChip(
                        'C',
                        _totalCarbs,
                        _selectedMealType!.carbs,
                        _remaining(_selectedMealType!.carbs, _totalCarbs),
                      ),
                      _remainChip(
                        'P',
                        _totalProtein,
                        _selectedMealType!.protein,
                        _remaining(_selectedMealType!.protein, _totalProtein),
                      ),
                      _remainChip(
                        'F',
                        _totalFat,
                        _selectedMealType!.fat,
                        _remaining(_selectedMealType!.fat, _totalFat),
                      ),
                    ],
                  ),
                ),

              // 3️⃣  ingredient autocomplete
              if (_selectedMealType != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Autocomplete<Ingredient>(
                    optionsBuilder: (val) {
                      if (val.text.isEmpty) return const Iterable.empty();
                      return ingredients.where((ing) => ing.name
                          .toLowerCase()
                          .contains(val.text.toLowerCase()));
                    },
                    displayStringForOption: (o) => o.name,
                    fieldViewBuilder:
                        (ctx, controller, focusNode, onSubmit) => TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Add Ingredient',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    onSelected: _addIngredient,
                  ),
                ),

              // 4️⃣  list of ingredient rows
              Expanded(
                child: _mealIngredients.isEmpty
                    ? const Center(child: Text('No ingredients yet.'))
                    : ListView.separated(
                        itemCount: _mealIngredients.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 0),
                        itemBuilder: (ctx, idx) => _IngredientRow(
                          key: ValueKey(_mealIngredients[idx]
                              .ingredient
                              .id), // stable key
                          mealIngredient: _mealIngredients[idx],
                          mealType: _selectedMealType!,
                          onDelete: () => _removeIngredient(idx),
                          onChanged: _onRowUpdated,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // pretty chip helper
  Widget _remainChip(
      String label, double used, double tgt, double? remain) {
    final over = remain! < 0;
    return Row(
      children: [
        Text(
          '$label: ${used.toStringAsFixed(1)}/${tgt.toStringAsFixed(1)} '
          '(${remain.abs().toStringAsFixed(1)}${over ? ' over' : ' left'})',
          style: TextStyle(
            color: over
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────  Ingredient Row Widget  ──────────────────────
class _IngredientRow extends StatefulWidget {
  final MealIngredient mealIngredient;
  final MealType mealType;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _IngredientRow({
    required super.key,
    required this.mealIngredient,
    required this.mealType,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  // Controllers persist; we NEVER re-create them after init
  late final TextEditingController _weightCtl;
  late final TextEditingController _cPctCtl;
  late final TextEditingController _pPctCtl;
  late final TextEditingController _fPctCtl;

  // Handy aliases
  MealIngredient get mi => widget.mealIngredient;
  Ingredient     get ing => mi.ingredient;

  @override
  void initState() {
    super.initState();
    _weightCtl = TextEditingController(text: mi.weight.toStringAsFixed(2));
    _cPctCtl   = TextEditingController();
    _pPctCtl   = TextEditingController();
    _fPctCtl   = TextEditingController();
    _refreshPctTexts();
  }

  @override
  void dispose() {
    _weightCtl.dispose();
    _cPctCtl.dispose();
    _pPctCtl.dispose();
    _fPctCtl.dispose();
    super.dispose();
  }

  // ───────────────────  helpers  ────────────────────────────────────────
  String _pct(double part, double total) =>
      (part / total * 100).toStringAsFixed(1);

  void _refreshPctTexts() {
    _cPctCtl.text = _pct(mi.carbs,   widget.mealType.carbs);
    _pPctCtl.text = _pct(mi.protein, widget.mealType.protein);
    _fPctCtl.text = _pct(mi.fat,     widget.mealType.fat);
  }

  // grams of macro per gram of ingredient
  double _gPerG(double macro) => macro / ing.defaultWeight;

  // Select-all when field gains focus
  void _selectAll(TextEditingController ctl) =>
      ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);

  // ───────────────────  weight field editing  ───────────────────────────
  void _applyNewWeight(String val) {
    final w = double.tryParse(val);
    if (w == null || w <= 0) return;

    setState(() {
      mi.weight = w;
      _weightCtl.text = w.toStringAsFixed(2);
      _refreshPctTexts();
    });
    widget.onChanged();
  }

  // ───────────────────  % field editing  ────────────────────────────────
  void _applyNewPct(String macroKey, String val) {
    final pct = double.tryParse(val);
    if (pct == null || pct < 0) return;

    double newWeight = mi.weight;

    switch (macroKey) {
      case 'C':
        if (ing.carbs == 0) return;
        newWeight = (widget.mealType.carbs * pct / 100) / _gPerG(ing.carbs);
        break;
      case 'P':
        if (ing.protein == 0) return;
        newWeight =
            (widget.mealType.protein * pct / 100) / _gPerG(ing.protein);
        break;
      case 'F':
        if (ing.fat == 0) return;
        newWeight = (widget.mealType.fat * pct / 100) / _gPerG(ing.fat);
        break;
    }

    setState(() {
      mi.weight = newWeight;
      _weightCtl.text = newWeight.toStringAsFixed(2);
      _refreshPctTexts();
    });
    widget.onChanged();
  }

  // ───────────────────  build  ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ing.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // row 1  –  weight + calories
          Row(
            children: [
              const Text('g: '),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _weightCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: _applyNewWeight,
                  onEditingComplete: () => _applyNewWeight(_weightCtl.text),
                  onTap: () => _selectAll(_weightCtl),
                ),
              ),
              const SizedBox(width: 12),
              Text('Cal ${mi.calories.toStringAsFixed(1)}'),
            ],
          ),
          // row 2  –  editable % of each macro
          Wrap(
            spacing: 12,
            children: [
              _pctField('C', _cPctCtl, ing.carbs   == 0),
              _pctField('P', _pPctCtl, ing.protein == 0),
              _pctField('F', _fPctCtl, ing.fat     == 0),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: widget.onDelete,
      ),
    );
  }

  // helper builds one % TextField
  Widget _pctField(
      String label, TextEditingController ctl, bool disabled) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: ctl,
        enabled: !disabled,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$label %',
          isDense: true,
        ),
        onTap: () => _selectAll(ctl),
        onSubmitted: (val) => _applyNewPct(label, val),
        onEditingComplete: () => _applyNewPct(label, ctl.text),
      ),
    );
  }
}
