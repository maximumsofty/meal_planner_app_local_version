// lib/screens/create_meal_screen.dart
//
// • Remaining bar shows totals of all rows
// • Unlocked % fields are relative to (target − lockedUsed)
// • Editing a % sets weight to that % of the *remaining* macro
// • Locked rows read-only and displayed in separate section

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
  // ── services & loads ──────────────────────────────────────────────────
  final _ingredientService = IngredientService();
  final _mealTypeService   = MealTypeService();
  late Future<List<Ingredient>> _allIngredientsFuture;
  late Future<List<MealType>>   _allMealTypesFuture;

  // ── user selections ───────────────────────────────────────────────────
  MealType? _selectedMealType;
  final List<MealIngredient> _mealIngredients = [];

  @override
  void initState() {
    super.initState();
    _allIngredientsFuture = _ingredientService.loadIngredients();
    _allMealTypesFuture   = _mealTypeService.loadMealTypes();
  }

  // ── helpers: locked / unlocked splits ─────────────────────────────────
  Iterable<MealIngredient> get _locked   =>
      _mealIngredients.where((mi) => mi.locked);
  Iterable<MealIngredient> get _unlocked =>
      _mealIngredients.where((mi) => !mi.locked);

  // totals of *all* rows (drive Remaining bar)
  double get _usedCarbsTotal   =>
      _mealIngredients.fold(0, (s, mi) => s + mi.carbs);
  double get _usedProteinTotal =>
      _mealIngredients.fold(0, (s, mi) => s + mi.protein);
  double get _usedFatTotal     =>
      _mealIngredients.fold(0, (s, mi) => s + mi.fat);

  // totals of locked rows
  double get _lockedCarbs   => _locked.fold(0, (s, mi) => s + mi.carbs);
  double get _lockedProtein => _locked.fold(0, (s, mi) => s + mi.protein);
  double get _lockedFat     => _locked.fold(0, (s, mi) => s + mi.fat);

  // remaining macros **after locked**
  double _remainingAfterLocked(double target, double lockedUsed) =>
      (target - lockedUsed).clamp(0, double.infinity);

  // ── callbacks ─────────────────────────────────────────────────────────
  void _onRowUpdated() => setState(() {});

  void _addIngredient(Ingredient ing) => setState(() =>
      _mealIngredients.add(
          MealIngredient(ingredient: ing, weight: ing.defaultWeight)));

  void _toggleLock(MealIngredient mi) =>
      setState(() => mi.locked = !mi.locked);

  void _removeIngredient(MealIngredient mi) =>
      setState(() => _mealIngredients.remove(mi));

  // ── UI ────────────────────────────────────────────────────────────────
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

          return Column(
            children: [
              // 1️⃣  MEAL-TYPE PICKER
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DropdownButtonFormField<MealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type (macro targets)',
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

              // 2️⃣  REMAINING BAR (all rows)
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
                        _usedCarbsTotal,
                        _selectedMealType!.carbs,
                        _selectedMealType!.carbs - _usedCarbsTotal,
                      ),
                      _remainChip(
                        'P',
                        _usedProteinTotal,
                        _selectedMealType!.protein,
                        _selectedMealType!.protein - _usedProteinTotal,
                      ),
                      _remainChip(
                        'F',
                        _usedFatTotal,
                        _selectedMealType!.fat,
                        _selectedMealType!.fat - _usedFatTotal,
                      ),
                    ],
                  ),
                ),

              // 3️⃣  AUTOCOMPLETE ADDER
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
                        (ctx, ctl, focus, onSubmit) => TextField(
                      controller: ctl,
                      focusNode: focus,
                      decoration: const InputDecoration(
                        labelText: 'Add Ingredient',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    onSelected: _addIngredient,
                  ),
                ),

              // 4️⃣  UNLOCKED LIST
              Expanded(
                child: _unlocked.isEmpty
                    ? const Center(child: Text('No ingredients yet.'))
                    : _buildList(
                        context,
                        _unlocked.toList(),
                        remainingCarbs:
                            _remainingAfterLocked(_selectedMealType!.carbs,
                                _lockedCarbs),
                        remainingProtein:
                            _remainingAfterLocked(_selectedMealType!.protein,
                                _lockedProtein),
                        remainingFat: _remainingAfterLocked(
                            _selectedMealType!.fat, _lockedFat),
                      ),
              ),

              // 5️⃣  LOCKED LIST
              if (_locked.isNotEmpty)
                Column(
                  children: [
                    const Divider(height: 0),
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      child: const Text('Locked Ingredients'),
                    ),
                    SizedBox(
                      height: 160,
                      child: _buildList(
                        context,
                        _locked.toList(),
                        remainingCarbs: 0,
                        remainingProtein: 0,
                        remainingFat: 0,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<MealIngredient> list, {
    required double remainingCarbs,
    required double remainingProtein,
    required double remainingFat,
  }) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (ctx, idx) {
        final mi = list[idx];
        return _IngredientRow(
          key: ValueKey(mi.ingredient.id),
          mealIngredient: mi,
          mealType: _selectedMealType!,
          remainingCarbs: remainingCarbs,
          remainingProtein: remainingProtein,
          remainingFat: remainingFat,
          onDelete: () => _removeIngredient(mi),
          onChanged: _onRowUpdated,
          onToggleLock: () => _toggleLock(mi),
        );
      },
    );
  }

  Widget _remainChip(String label, double used, double tgt, double remain) {
    final over = remain < 0;
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

// ──────────────────────  Ingredient Row ────────────────────────────────
class _IngredientRow extends StatefulWidget {
  final MealIngredient mealIngredient;
  final MealType mealType;
  final double remainingCarbs;   // after locked
  final double remainingProtein; // after locked
  final double remainingFat;     // after locked
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback onToggleLock;

  const _IngredientRow({
    required super.key,
    required this.mealIngredient,
    required this.mealType,
    required this.remainingCarbs,
    required this.remainingProtein,
    required this.remainingFat,
    required this.onDelete,
    required this.onChanged,
    required this.onToggleLock,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late final TextEditingController _weightCtl;
  late final TextEditingController _cPctCtl;
  late final TextEditingController _pPctCtl;
  late final TextEditingController _fPctCtl;

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
  void didUpdateWidget(covariant _IngredientRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshPctTexts(); // keep % fresh when remaining changes
  }

  @override
  void dispose() {
    _weightCtl.dispose();
    _cPctCtl.dispose();
    _pPctCtl.dispose();
    _fPctCtl.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────
  String _pctOf(double part, double denom) =>
      denom == 0 ? '0.0' : (part / denom * 100).toStringAsFixed(1);

  void _refreshPctTexts() {
    _cPctCtl.text =
        _pctOf(mi.carbs,   widget.remainingCarbs);
    _pPctCtl.text =
        _pctOf(mi.protein, widget.remainingProtein);
    _fPctCtl.text =
        _pctOf(mi.fat,     widget.remainingFat);
  }

  double _gPerG(double macro) => macro / ing.defaultWeight;

  void _selectAll(TextEditingController ctl) =>
      ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);

  // weight editing
  void _applyNewWeight(String val) {
    if (mi.locked) return;
    final w = double.tryParse(val);
    if (w == null || w <= 0) return;

    setState(() {
      mi.weight = w;
      _weightCtl.text = w.toStringAsFixed(2);
      _refreshPctTexts();
    });
    widget.onChanged();
  }

  // % editing (relative to remaining after locked)
  void _applyNewPct(String macroKey, String val) {
    if (mi.locked) return;
    final pct = double.tryParse(val);
    if (pct == null || pct < 0) return;

    double newWeight = mi.weight;

    switch (macroKey) {
      case 'C':
        if (ing.carbs == 0 || widget.remainingCarbs == 0) return;
        newWeight = (widget.remainingCarbs * pct / 100) / _gPerG(ing.carbs);
        break;
      case 'P':
        if (ing.protein == 0 || widget.remainingProtein == 0) return;
        newWeight =
            (widget.remainingProtein * pct / 100) / _gPerG(ing.protein);
        break;
      case 'F':
        if (ing.fat == 0 || widget.remainingFat == 0) return;
        newWeight = (widget.remainingFat * pct / 100) / _gPerG(ing.fat);
        break;
    }

    setState(() {
      mi.weight = newWeight;
      _weightCtl.text = newWeight.toStringAsFixed(2);
      _refreshPctTexts();
    });
    widget.onChanged();
  }

  // ── build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(mi.locked ? Icons.lock : Icons.lock_open),
        onPressed: widget.onToggleLock,
      ),
      title: Text(ing.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // row 1: weight + calories
          Row(
            children: [
              const Text('g: '),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _weightCtl,
                  enabled: !mi.locked,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: _applyNewWeight,
                  onEditingComplete: () =>
                      _applyNewWeight(_weightCtl.text),
                  onTap: () => _selectAll(_weightCtl),
                ),
              ),
              const SizedBox(width: 12),
              Text('Cal ${mi.calories.toStringAsFixed(1)}'),
            ],
          ),
          // row 2: % fields
          Wrap(
            spacing: 12,
            children: [
              _pctField('C', _cPctCtl, ing.carbs == 0),
              _pctField('P', _pPctCtl, ing.protein == 0),
              _pctField('F', _fPctCtl, ing.fat == 0),
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

  Widget _pctField(
      String label, TextEditingController ctl, bool disabled) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: ctl,
        enabled: !disabled && !mi.locked,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label %', isDense: true),
        onTap: () => _selectAll(ctl),
        onSubmitted: (v) => _applyNewPct(label, v),
        onEditingComplete: () => _applyNewPct(label, ctl.text),
      ),
    );
  }
}
