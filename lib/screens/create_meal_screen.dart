// lib/screens/create_meal_screen.dart
//
// Full Meal-Builder with independent auto-fillers for Carbs / Protein / Fat.

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';
import '../models/meal_type.dart';
import '../services/ingredient_service.dart';
import '../services/meal_type_service.dart';
import '../services/meal_service.dart';   // NEW
import '../models/meal.dart';             // NEW
import 'dart:convert';                      // for jsonEncode/jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key});

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  // ─────────────────── services & initial loads ────────────────────────
  final _ingredientService = IngredientService();
  final _mealTypeService   = MealTypeService();
  final _mealService = MealService();     // NEW
  static const _draftKey = 'meal_builder_draft';                   // NEW
  late Future<List<Ingredient>> _allIngredientsFuture;
  late Future<List<MealType>>   _allMealTypesFuture;
  late final ScrollController _listController; // NEW
  static const _lastFillerKeyC = 'last_filler_carb';     // ✅ now legal
  static const _lastFillerKeyP = 'last_filler_protein';
  static const _lastFillerKeyF = 'last_filler_fat';

  // ─────────────────── state ────────────────────────────────────────────
  MealType? _selectedMealType;
  final List<MealIngredient> _mainRows = [];  // user-added rows

  MealIngredient? _fillerCarb;
  MealIngredient? _fillerProtein;
  MealIngredient? _fillerFat;

  @override
  void initState() {
    super.initState();
    _listController = ScrollController();
    _allIngredientsFuture = _ingredientService.loadIngredients();
    _allMealTypesFuture   = _mealTypeService.loadMealTypes();
    _allIngredientsFuture.then((ings) => _loadDraft(ings));
        // If no draft loaded and user starts fresh, pre-select last fillers
    _allIngredientsFuture.then((ings) async {
      final prefs = await SharedPreferences.getInstance();
      Map<String, String?> ids = {
        'C': prefs.getString(_lastFillerKeyC),
        'P': prefs.getString(_lastFillerKeyP),
        'F': prefs.getString(_lastFillerKeyF),
      };
            Ingredient? _getIng(String? id) {
        if (id == null) return null;
        for (final i in ings) {
          if (i.id == id) return i;
        }
        return null; // no match
      }

      _chooseFiller('C', _getIng(prefs.getString(_lastFillerKeyC)));
      _chooseFiller('P', _getIng(prefs.getString(_lastFillerKeyP)));
      _chooseFiller('F', _getIng(prefs.getString(_lastFillerKeyF)));

    });

  }
  @override
  void dispose() {
    _listController.dispose();   // dispose the ScrollController
    super.dispose();             // always call super.dispose()
  }
  
  // ─────────────────── helpers: lists & totals ─────────────────────────
  Iterable<MealIngredient> get _lockedMain =>
      _mainRows.where((mi) => mi.locked);
  Iterable<MealIngredient> get _unlockedMain =>
      _mainRows.where((mi) => !mi.locked);

  List<MealIngredient> get _allFillers => [
        if (_fillerCarb != null) _fillerCarb!,
        if (_fillerProtein != null) _fillerProtein!,
        if (_fillerFat != null) _fillerFat!,
      ];

  double _sumCarbs(Iterable<MealIngredient> rows) =>
      rows.fold(0, (s, mi) => s + mi.carbs);
  double _sumProt (Iterable<MealIngredient> rows) =>
      rows.fold(0, (s, mi) => s + mi.protein);
  double _sumFat  (Iterable<MealIngredient> rows) =>
      rows.fold(0, (s, mi) => s + mi.fat);

  double get _usedCarbsTotal   =>
      _sumCarbs(_mainRows) + _sumCarbs(_allFillers);
  double get _usedProteinTotal =>
      _sumProt(_mainRows) + _sumProt(_allFillers);
  double get _usedFatTotal     =>
      _sumFat (_mainRows) + _sumFat (_allFillers);

  double get _lockedCarbs   => _sumCarbs(_lockedMain);
  double get _lockedProtein => _sumProt (_lockedMain);
  double get _lockedFat     => _sumFat  (_lockedMain);

  double _remainAfterLocked(double target, double locked) =>
      (target - locked).clamp(0, double.infinity);

  // ─────────────────── filler utilities ────────────────────────────────
  List<Ingredient> _singleMacro(List<Ingredient> all, String macro) {
    const eps = 0.01;
    bool ok(Ingredient i) {
      switch (macro) {
        case 'C':
          return i.carbs > eps && i.protein <= eps && i.fat <= eps;
        case 'P':
          return i.protein > eps && i.carbs <= eps && i.fat <= eps;
        case 'F':
          return i.fat > eps && i.carbs <= eps && i.protein <= eps;
      }
      return false;
    }

    return all.where(ok).toList();
  }

  Future<void> _saveLastFiller(String macro, Ingredient? ing) async {
    final prefs = await SharedPreferences.getInstance();
    final key = {
      'C': _lastFillerKeyC,
      'P': _lastFillerKeyP,
      'F': _lastFillerKeyF,
    }[macro]!;
    if (ing == null) {
      prefs.remove(key);
    } else {
      prefs.setString(key, ing.id);
    }
  }

  void _chooseFiller(String macro, Ingredient? ing) {
    // remove old filler weight from totals
    void _removeOld(MealIngredient? mi) {
      if (mi != null) _allFillers.remove(mi);
    }

    _removeOld(_fillerCarb);
    _removeOld(_fillerProtein);
    _removeOld(_fillerFat);

    MealIngredient? newMI;
    if (ing != null) {
      newMI = MealIngredient(ingredient: ing, weight: 0)..locked = true;
    }

    setState(() {
      switch (macro) {
        case 'C':
          _fillerCarb = newMI;
          break;
        case 'P':
          _fillerProtein = newMI;
          break;
        case 'F':
          _fillerFat = newMI;
          break;
          }
      _recalcFillerWeights();
    });
  _saveDraft();            // NEW
  _saveLastFiller(macro, ing);          // NEW – remember choice

}
  // ── Save-meal dialog ──────────────────────────────────────────────────
  Future<void> _showSaveDialog() async {
    final nameCtl = TextEditingController(
      text: 'Meal ${DateTime.now().toIso8601String().substring(0, 16)}',
    );
    bool fav = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Meal name'),
            ),
            Row(
              children: [
                Checkbox(
                  value: fav,
                  onChanged: (v) {
                    fav = v ?? false;
                    (ctx as Element).markNeedsBuild();
                  },
                ),
                const Text('Favorite'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // build rows list in visible order: fillers -> unlocked -> locked
    final rows = [
      ..._allFillers,
      ..._unlockedMain,
      ..._lockedMain,
    ].map((mi) => MealIngredient(
          ingredient: mi.ingredient,
          weight: mi.weight,
        )..locked = mi.locked).toList();

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtl.text.trim(),
      favorite: fav,
      createdAt: DateTime.now(),
      mealTypeId: _selectedMealType!.id,
      rows: rows,
    );

    await _mealService.addMeal(meal);
    // clear draft
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_draftKey);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal saved')),
    );
  }

   // ───────────────── recalc filler weights (fixed types) ─────────────────
  // ── Draft persistence ────────────────────────────────────────────────
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final draft = {
      'mealTypeId': _selectedMealType?.id,
      'mainRows': _mainRows.map((mi) => {
            'ingredient': mi.ingredient.toJson(),
            'weight': mi.weight,
            'locked': mi.locked,
          }).toList(),
      'fillerC': _fillerCarb?.ingredient.toJson(),
      'fillerP': _fillerProtein?.ingredient.toJson(),
      'fillerF': _fillerFat?.ingredient.toJson(),
    };

    await prefs.setString(_draftKey, jsonEncode(draft));
  }
  // ── Draft restoration (awaits loadMealTypes) ──────────────────────────
  Future<void> _loadDraft(List<Ingredient> allIngredients) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_draftKey);
    if (str == null) return;

    final draft = jsonDecode(str);

    // Fetch meal types so we can match the saved ID
    final mealTypes = await _mealTypeService.loadMealTypes();

    setState(() {
      // MealType
      final mtId = draft['mealTypeId'];
      if (mtId != null) {
        _selectedMealType =
            mealTypes.firstWhere((mt) => mt.id == mtId, orElse: () => _selectedMealType!);
      }

      // Main rows
      _mainRows.clear();
      for (final row in draft['mainRows'] ?? []) {
        final ingJson = row['ingredient'] as Map<String, dynamic>;
        final ing = allIngredients.firstWhere(
          (i) => i.id == ingJson['id'],
          orElse: () => Ingredient.fromJson(ingJson),
        );
        _mainRows.add(
          MealIngredient(ingredient: ing, weight: (row['weight'] as num).toDouble())
            ..locked = row['locked'] as bool,
        );
      }

      // Fillers
      Ingredient? _getIng(Map<String, dynamic>? j) =>
          j == null ? null : allIngredients.firstWhere(
                (i) => i.id == j['id'],
                orElse: () => Ingredient.fromJson(j),
              );

      _chooseFiller('C', _getIng(draft['fillerC']));
      _chooseFiller('P', _getIng(draft['fillerP']));
      _chooseFiller('F', _getIng(draft['fillerF']));

      _recalcFillerWeights();
    });
  }


void _recalcFillerWeights() {
  if (_selectedMealType == null) return;

  // Remaining = target − ALL main rows (locked + unlocked)
  final double remC = (_selectedMealType!.carbs   -
          _sumCarbs(_mainRows))
      .clamp(0.0, double.infinity)
      .toDouble();
  final double remP = (_selectedMealType!.protein -
          _sumProt(_mainRows))
      .clamp(0.0, double.infinity)
      .toDouble();
  final double remF = (_selectedMealType!.fat     -
          _sumFat(_mainRows))
      .clamp(0.0, double.infinity)
      .toDouble();

  void setWeight(MealIngredient? mi, double remaining, double gramsPerGram) {
    if (mi == null || gramsPerGram == 0.0) return;
    mi.weight = double.parse((remaining / gramsPerGram).toStringAsFixed(1));
  }

  setWeight(
    _fillerCarb,
    remC,
    _fillerCarb == null
        ? 0.0
        : _fillerCarb!.ingredient.carbs /
            _fillerCarb!.ingredient.defaultWeight,
  );

  setWeight(
    _fillerProtein,
    remP,
    _fillerProtein == null
        ? 0.0
        : _fillerProtein!.ingredient.protein /
            _fillerProtein!.ingredient.defaultWeight,
  );

  setWeight(
    _fillerFat,
    remF,
    _fillerFat == null
        ? 0.0
        : _fillerFat!.ingredient.fat /
            _fillerFat!.ingredient.defaultWeight,
  );
}



  // ─────────────────── row callbacks ────────────────────────────────────
  void _onRowChanged() {
    _recalcFillerWeights();
    setState(() {});
    _saveDraft();            // NEW
  }

  void _addMainRow(Ingredient ing) {
    setState(() {
      _mainRows
          .add(MealIngredient(ingredient: ing, weight: ing.defaultWeight));
      _recalcFillerWeights();
    });
    _saveDraft();            // NEW
  }

  void _toggleLock(MealIngredient mi) {
    setState(() {
      mi.locked = !mi.locked;
      _recalcFillerWeights();
    });
    _saveDraft();            // NEW
  }

  void _removeRow(MealIngredient mi) {
    setState(() {
      _mainRows.remove(mi);
      _recalcFillerWeights();
    });
    _saveDraft();            // NEW
  }

  // ─────────────────── UI build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Builder'),
        actions: [
          if (_selectedMealType != null &&
              (_mainRows.isNotEmpty || _allFillers.isNotEmpty))
            IconButton(
              tooltip: 'Save meal',
              icon: const Icon(Icons.save),
              onPressed: _showSaveDialog,   // NEW
            ),
        ],
      ),

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
              // meal-type picker
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DropdownButtonFormField<MealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: mealTypes
                      .map((mt) => DropdownMenuItem(
                            value: mt,
                            child: Text(mt.name),
                          ))
                      .toList(),
                  onChanged: (mt) {
                    setState(() {
                      _selectedMealType = mt;
                      _mainRows.clear();
                      _fillerCarb = _fillerProtein = _fillerFat = null;
                    });
                  },
                ),
              ),
              // remaining bar
              if (_selectedMealType != null)
                Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _remainChip('C', _usedCarbsTotal,
                          _selectedMealType!.carbs),
                      _remainChip('P', _usedProteinTotal,
                          _selectedMealType!.protein),
                      _remainChip(
                          'F', _usedFatTotal, _selectedMealType!.fat),
                    ],
                  ),
                ),
              // filler pickers
              if (_selectedMealType != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Column(
                    children: [
                      _fillerPicker(
                        macro: 'C',
                        label: 'Carb filler',
                        current: _fillerCarb?.ingredient,
                        choices: _singleMacro(ingredients, 'C'),
                      ),
                      _fillerPicker(
                        macro: 'P',
                        label: 'Protein filler',
                        current: _fillerProtein?.ingredient,
                        choices: _singleMacro(ingredients, 'P'),
                      ),
                      _fillerPicker(
                        macro: 'F',
                        label: 'Fat filler',
                        current: _fillerFat?.ingredient,
                        choices: _singleMacro(ingredients, 'F'),
                      ),
                    ],
                  ),
                ),
              // autocomplete adder
              if (_selectedMealType != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Autocomplete<Ingredient>(
                    optionsBuilder: (val) => val.text.isEmpty
                        ? const Iterable<Ingredient>.empty()
                        : ingredients.where((i) => i.name
                            .toLowerCase()
                            .contains(val.text.toLowerCase())),
                    displayStringForOption: (i) => i.name,
                    fieldViewBuilder:
                        (ctx, ctl, focus, _) => TextField(
                      controller: ctl,
                      focusNode: focus,
                      decoration: const InputDecoration(
                        labelText: 'Add Ingredient',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    onSelected: _addMainRow,
                  ),
                ),
              // ── ONE combined scrollable list (fillers → unlocked → locked) ──────────
Expanded(
  child: ListView(
    key: const PageStorageKey('meal-scroll'), // KEEP scroll offset
    controller: _listController,
    children: [
      // Fillers ----------------------------------------------------------
      if (_allFillers.isNotEmpty) ...[
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: const Text('Fillers (auto)'),
        ),
        ..._allFillers.map(
          (mi) => _IngredientRow(
            key: ValueKey(mi),
            mealIngredient: mi,
            mealType: _selectedMealType!,
            remainingCarbs: 0,
            remainingProtein: 0,
            remainingFat: 0,
            editable: false,
            onChange: _onRowChanged,
            onDelete: null,            // read-only
            onLockToggle: () {},        // always locked
          ),
        ),
        const Divider(height: 0),
      ],

      // Unlocked ---------------------------------------------------------
      if (_unlockedMain.isNotEmpty) ...[
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: const Text('Unlocked'),
        ),
        ..._unlockedMain.map(
          (mi) => _IngredientRow(
            key: ValueKey(mi),
            mealIngredient: mi,
            mealType: _selectedMealType!,
            remainingCarbs: _remainAfterLocked(
                _selectedMealType!.carbs, _lockedCarbs),
            remainingProtein: _remainAfterLocked(
                _selectedMealType!.protein, _lockedProtein),
            remainingFat:
                _remainAfterLocked(_selectedMealType!.fat, _lockedFat),
            editable: true,
            onChange: _onRowChanged,
            onDelete: () => _removeRow(mi),
            onLockToggle: () => _toggleLock(mi),
          ),
        ),
        const Divider(height: 0),
      ],

      // Locked -----------------------------------------------------------
      if (_lockedMain.isNotEmpty) ...[
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: const Text('Locked'),
        ),
        ..._lockedMain.map(
          (mi) => _IngredientRow(
            key: ValueKey(mi),
            mealIngredient: mi,
            mealType: _selectedMealType!,
            remainingCarbs: 0,
            remainingProtein: 0,
            remainingFat: 0,
            editable: false,
            onChange: _onRowChanged,
            onDelete: () => _removeRow(mi),        // locked rows deletable 
            onLockToggle: () => _toggleLock(mi),
          ),
        ),
      ],
      // Summary ---------------------------------------------------------
      ..._summarySection(),

      // Empty state ------------------------------------------------------
      if (_allFillers.isEmpty &&
          _unlockedMain.isEmpty &&
          _lockedMain.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No ingredients yet.')),
        ),
    ],
  ),
),

            ],
          );
        },
      ),
    );
  }

  // ─── small widgets helpers ────────────────────────────────────────────
  Widget _remainChip(String lbl, double used, double tgt) {
    final remain = tgt - used;
    final over = remain < 0;
    return Row(
      children: [
        Text(
          '$lbl: ${used.toStringAsFixed(1)}/${tgt.toStringAsFixed(1)} '
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

  Widget _fillerPicker({
    required String macro,
    required String label,
    required Ingredient? current,
    required List<Ingredient> choices,
  }) {
    return DropdownButtonFormField<Ingredient>(
      value: current,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        const DropdownMenuItem<Ingredient>(
          value: null,
          child: Text('— None —'),
        ),
        ...choices.map((i) => DropdownMenuItem(value: i, child: Text(i.name)))
      ],
      onChanged: (ing) => _chooseFiller(macro, ing),
    );
  }
  // ── Meal summary section ─────────────────────────────────────────────
  List<Widget> _summarySection() {
    final rowsInOrder = [
      ..._allFillers,
      ..._unlockedMain,
      ..._lockedMain,
    ];

    if (rowsInOrder.isEmpty) return [];

    return [
      const Divider(height: 0),
      Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant,
        padding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Text('Meal Summary (g)'),
      ),
      ...rowsInOrder.map(
        (mi) => Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mi.ingredient.name),
              Text('${mi.weight.toStringAsFixed(1)} g'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }


}

// ───────────────────── Ingredient Row widget ────────────────────────────
class _IngredientRow extends StatefulWidget {
  final MealIngredient mealIngredient;
  final MealType mealType;
  final double remainingCarbs;
  final double remainingProtein;
  final double remainingFat;
  final bool editable;
  final VoidCallback onChange;
  final VoidCallback? onDelete;
  final VoidCallback onLockToggle;

  const _IngredientRow({
    required super.key,
    required this.mealIngredient,
    required this.mealType,
    required this.remainingCarbs,
    required this.remainingProtein,
    required this.remainingFat,
    required this.editable,
    required this.onChange,
    required this.onDelete,
    required this.onLockToggle,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late final TextEditingController _gCtl;
  late final TextEditingController _cPctCtl;
  late final TextEditingController _pPctCtl;
  late final TextEditingController _fPctCtl;

  MealIngredient get mi => widget.mealIngredient;
  Ingredient     get ing => mi.ingredient;

  @override
  void initState() {
    super.initState();
    _gCtl = TextEditingController(text: mi.weight.toStringAsFixed(1));
    _cPctCtl = TextEditingController();
    _pPctCtl = TextEditingController();
    _fPctCtl = TextEditingController();
    _refreshPct();
  }
@override
  void didUpdateWidget(covariant _IngredientRow old) {
    super.didUpdateWidget(old);
    _refreshPct();
  }

  void _refreshPct() {
    String pct(double part, double denom) =>
        denom == 0 ? '0.0' : (part / denom * 100).toStringAsFixed(1);
    _cPctCtl.text = pct(mi.carbs, widget.remainingCarbs);
    _pPctCtl.text = pct(mi.protein, widget.remainingProtein);
    _fPctCtl.text = pct(mi.fat, widget.remainingFat);
  }

  void _selectAll(TextEditingController c) =>
      c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);

  double _gPerG(double macro) => macro / ing.defaultWeight;

  void _setWeight(double w) {
    mi.weight = w;
    _gCtl.text = w.toStringAsFixed(1);
    _refreshPct();
    widget.onChange();
  }

  void _weightSubmit(String v) {
    if (!widget.editable) return;
    final d = double.tryParse(v);
    if (d != null && d > 0) _setWeight(d);
  }

  void _pctSubmit(String macro, String v) {
    if (!widget.editable) return;
    final pct = double.tryParse(v);
    if (pct == null || pct < 0) return;

    double newW = mi.weight;
    switch (macro) {
      case 'C':
        if (ing.carbs == 0 || widget.remainingCarbs == 0) return;
        newW =
            (widget.remainingCarbs * pct / 100) / _gPerG(ing.carbs);
        break;
      case 'P':
        if (ing.protein == 0 || widget.remainingProtein == 0) return;
        newW =
            (widget.remainingProtein * pct / 100) / _gPerG(ing.protein);
        break;
      case 'F':
        if (ing.fat == 0 || widget.remainingFat == 0) return;
        newW =
            (widget.remainingFat * pct / 100) / _gPerG(ing.fat);
        break;
    }
    _setWeight(newW);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(mi.locked ? Icons.lock : Icons.lock_open),
        onPressed: widget.onLockToggle,
      ),
      title: Text(ing.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('g: '),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _gCtl,
                  enabled: widget.editable,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: _weightSubmit,
                  onTap: () => _selectAll(_gCtl),
                ),
              ),
              const SizedBox(width: 12),
              Text('Cal ${mi.calories.toStringAsFixed(1)}'),
            ],
          ),
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
      trailing: widget.onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            )
          : null,
    );
  }

  Widget _pctField(String lbl, TextEditingController c, bool disabled) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: c,
        enabled: !disabled && widget.editable,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$lbl %', isDense: true),
        onTap: () => _selectAll(c),
        onSubmitted: (v) => _pctSubmit(lbl, v),
      ),
    );
  }
}
