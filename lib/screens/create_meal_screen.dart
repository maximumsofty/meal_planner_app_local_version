// lib/screens/create_meal_screen.dart
//
// Full Meal-Builder with independent auto-fillers for Carbs / Protein / Fat.

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';
import '../models/meal_type.dart';
import '../services/ingredient_service.dart';
import '../services/meal_type_service.dart';
import '../services/meal_service.dart'; // NEW
import '../models/meal.dart'; // NEW
import 'dart:convert'; // for jsonEncode/jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/meal_ingredient_row.dart';

class CreateMealScreen extends StatefulWidget {
  final Meal? initialMeal;

  const CreateMealScreen({super.key, this.initialMeal});

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  // ─────────────────── services & initial loads ────────────────────────
  final _ingredientService = IngredientService();
  final _mealTypeService = MealTypeService();
  final _mealService = MealService(); // NEW
  static const _draftKey = 'meal_builder_draft'; // NEW
  late Future<List<Ingredient>> _allIngredientsFuture;
  late Future<List<MealType>> _allMealTypesFuture;
  late final ScrollController _listController; // NEW
  static const _lastFillerKeyC = 'last_filler_carb'; // ✅ now legal
  static const _lastFillerKeyP = 'last_filler_protein';
  static const _lastFillerKeyF = 'last_filler_fat';

  // ─────────────────── state ────────────────────────────────────────────
  MealType? _selectedMealType;
  final List<MealIngredient> _mainRows = []; // user-added rows

  MealIngredient? _fillerCarb;
  MealIngredient? _fillerProtein;
  MealIngredient? _fillerFat;
  bool _fillersExpanded = true;
  late final bool _persistDraft;

  @override
  void initState() {
    super.initState();
    _persistDraft = widget.initialMeal == null;
    _listController = ScrollController();
    _allIngredientsFuture = _ingredientService.loadIngredients();
    _allMealTypesFuture = _mealTypeService.loadMealTypes();
    _allIngredientsFuture.then((ings) async {
      if (widget.initialMeal != null) {
        await _loadFromMeal(widget.initialMeal!, ings);
      } else {
        final loadedDraft = await _loadDraft(ings);
        if (!loadedDraft) {
          await _preselectLastFillers(ings);
        }
      }
    });
  }

  @override
  void dispose() {
    _listController.dispose(); // dispose the ScrollController
    super.dispose(); // always call super.dispose()
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
  double _sumProt(Iterable<MealIngredient> rows) =>
      rows.fold(0, (s, mi) => s + mi.protein);
  double _sumFat(Iterable<MealIngredient> rows) =>
      rows.fold(0, (s, mi) => s + mi.fat);

  double get _usedCarbsTotal => _sumCarbs(_mainRows);
  double get _usedProteinTotal => _sumProt(_mainRows);
  double get _usedFatTotal => _sumFat(_mainRows);

  double get _lockedCarbs => _sumCarbs(_lockedMain);
  double get _lockedProtein => _sumProt(_lockedMain);
  double get _lockedFat => _sumFat(_lockedMain);

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

  Future<void> _preselectLastFillers(List<Ingredient> all) async {
    final prefs = await SharedPreferences.getInstance();

    Ingredient? resolve(String? id) {
      if (id == null) return null;
      for (final ing in all) {
        if (ing.id == id) return ing;
      }
      return null;
    }

    final carb = resolve(prefs.getString(_lastFillerKeyC));
    final protein = resolve(prefs.getString(_lastFillerKeyP));
    final fat = resolve(prefs.getString(_lastFillerKeyF));

    if (carb != null) _chooseFiller('C', carb);
    if (protein != null) _chooseFiller('P', protein);
    if (fat != null) _chooseFiller('F', fat);
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
    void removeOld(MealIngredient? mi) {
      if (mi != null) _allFillers.remove(mi);
    }

    removeOld(_fillerCarb);
    removeOld(_fillerProtein);
    removeOld(_fillerFat);

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
    _persist();
    _saveLastFiller(macro, ing);
  }

  // ── Reset builder ─────────────────────────────────────────────────────
  Future<void> _resetBuilder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset meal builder?'),
        content: const Text(
          'This will remove all unlocked and locked ingredients and clear the meal type. '
          'Filler selections will be kept.',
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

    if (ok != true) return;

    setState(() {
      _mainRows.clear();
      _selectedMealType = null; // force user to choose meal type again
    });

    _recalcFillerWeights(); // safe; returns early when meal type is null
    if (_persistDraft) {
      await _saveDraft(); // persist the cleared state (fillers remain)
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Builder reset')));
  }

  // ── Save-meal dialog ──────────────────────────────────────────────────
  Future<void> _showSaveDialog() async {
    final editingMeal = widget.initialMeal;
    final isEditing = editingMeal != null;

    final nameCtl = TextEditingController(
      text: isEditing
          ? editingMeal!.name
          : 'Meal ${DateTime.now().toIso8601String().substring(0, 16)}',
    );
    bool fav = editingMeal?.favorite ?? false;
    bool saveAsNew = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Save Meal' : 'Save Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Meal name'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: fav,
                onChanged: (v) => setDialogState(() => fav = v ?? false),
                title: const Text('Favorite'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (isEditing)
                SwitchListTile(
                  value: saveAsNew,
                  onChanged: (v) => setDialogState(() => saveAsNew = v),
                  title: const Text('Save as new meal'),
                  subtitle: const Text(
                    'Keep the original meal and create a copy.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameCtl.dispose();
      return;
    }

    // build rows list in visible order: fillers -> unlocked -> locked
    final rows = [..._allFillers, ..._unlockedMain, ..._lockedMain]
        .map(
          (mi) =>
              MealIngredient(ingredient: mi.ingredient, weight: mi.weight)
                ..locked = mi.locked,
        )
        .toList();

    final now = DateTime.now();
    final trimmedName = nameCtl.text.trim().isEmpty
        ? 'Meal ${now.toIso8601String().substring(0, 16)}'
        : nameCtl.text.trim();

    final meal = Meal(
      id: (!isEditing || saveAsNew)
          ? now.millisecondsSinceEpoch.toString()
          : editingMeal!.id,
      name: trimmedName,
      favorite: fav,
      createdAt: now,
      mealTypeId: _selectedMealType!.id,
      rows: rows,
    );

    if (isEditing && !saveAsNew) {
      await _mealService.upsertMeal(meal);
    } else {
      await _mealService.addMeal(meal);
    }

    if (_persistDraft) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing && !saveAsNew ? 'Meal updated' : 'Meal saved'),
      ),
    );

    nameCtl.dispose();
  }

  // ───────────────── recalc filler weights (fixed types) ─────────────────
  // ── Draft persistence ────────────────────────────────────────────────
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final draft = {
      'mealTypeId': _selectedMealType?.id,
      'mainRows': _mainRows
          .map(
            (mi) => {
              'ingredient': mi.ingredient.toJson(),
              'weight': mi.weight,
              'locked': mi.locked,
            },
          )
          .toList(),
      'fillerC': _fillerCarb?.ingredient.toJson(),
      'fillerP': _fillerProtein?.ingredient.toJson(),
      'fillerF': _fillerFat?.ingredient.toJson(),
      'fillersExpanded': _fillersExpanded,
    };

    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  // ── Draft restoration (awaits loadMealTypes) ──────────────────────────
  Future<bool> _loadDraft(List<Ingredient> allIngredients) async {
    if (!_persistDraft) return false;

    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_draftKey);
    if (str == null) return false;

    final draft = jsonDecode(str) as Map<String, dynamic>;
    final mealTypes = await _mealTypeService.loadMealTypes();

    setState(() {
      final mtId = draft['mealTypeId'] as String?;
      if (mtId != null) {
        final idx = mealTypes.indexWhere((mt) => mt.id == mtId);
        if (idx != -1) {
          _selectedMealType = mealTypes[idx];
        }
      }

      _mainRows.clear();
      for (final row in draft['mainRows'] as List<dynamic>? ?? []) {
        final rowMap = row as Map<String, dynamic>;
        final ingJson = rowMap['ingredient'] as Map<String, dynamic>;
        final ingredient = allIngredients.firstWhere(
          (i) => i.id == ingJson['id'],
          orElse: () => Ingredient.fromJson(ingJson),
        );
        final mi = MealIngredient(
          ingredient: ingredient,
          weight: (rowMap['weight'] as num).toDouble(),
        )..locked = rowMap['locked'] as bool;
        _mainRows.add(mi);
      }

      Ingredient? resolve(Map<String, dynamic>? json) => json == null
          ? null
          : allIngredients.firstWhere(
              (i) => i.id == json['id'],
              orElse: () => Ingredient.fromJson(json),
            );

      final fillerC = resolve(draft['fillerC'] as Map<String, dynamic>?);
      final fillerP = resolve(draft['fillerP'] as Map<String, dynamic>?);
      final fillerF = resolve(draft['fillerF'] as Map<String, dynamic>?);

      _fillerCarb = fillerC == null
          ? null
          : (MealIngredient(ingredient: fillerC, weight: 0)..locked = true);
      _fillerProtein = fillerP == null
          ? null
          : (MealIngredient(ingredient: fillerP, weight: 0)..locked = true);
      _fillerFat = fillerF == null
          ? null
          : (MealIngredient(ingredient: fillerF, weight: 0)..locked = true);

      _fillersExpanded = draft['fillersExpanded'] as bool? ?? true;
      _recalcFillerWeights();
    });

    return true;
  }

  Future<void> _loadFromMeal(Meal meal, List<Ingredient> allIngredients) async {
    final mealTypes = await _mealTypeService.loadMealTypes();

    setState(() {
      final idx = mealTypes.indexWhere((mt) => mt.id == meal.mealTypeId);
      if (idx != -1) {
        _selectedMealType = mealTypes[idx];
      } else {
        _selectedMealType = null;
      }

      _mainRows
        ..clear()
        ..addAll(
          meal.rows.map((row) {
            final ingredient = allIngredients.firstWhere(
              (ing) => ing.id == row.ingredient.id,
              orElse: () => row.ingredient,
            );
            final mi = MealIngredient(
              ingredient: ingredient,
              weight: row.weight,
            )..locked = row.locked;
            return mi;
          }),
        );

      _fillerCarb = null;
      _fillerProtein = null;
      _fillerFat = null;
      _fillersExpanded = true;
      _recalcFillerWeights();
    });
  }

  void _recalcFillerWeights() {
    if (_selectedMealType == null) return;

    // Remaining = target − ALL main rows (locked + unlocked)
    final double remC = (_selectedMealType!.carbs - _sumCarbs(_mainRows))
        .clamp(0.0, double.infinity)
        .toDouble();
    final double remP = (_selectedMealType!.protein - _sumProt(_mainRows))
        .clamp(0.0, double.infinity)
        .toDouble();
    final double remF = (_selectedMealType!.fat - _sumFat(_mainRows))
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
          : _fillerFat!.ingredient.fat / _fillerFat!.ingredient.defaultWeight,
    );
  }

  void _persist() {
    if (!_persistDraft) return;
    _saveDraft();
  }

  // ─────────────────── row callbacks ────────────────────────────────────
  void _onRowChanged() {
    _recalcFillerWeights();
    setState(() {});
    _persist();
  }

  void _addMainRow(Ingredient ing) {
    setState(() {
      _mainRows.add(MealIngredient(ingredient: ing, weight: ing.defaultWeight));
      _recalcFillerWeights();
    });
    _persist();
  }

  void _toggleLock(MealIngredient mi) {
    setState(() {
      mi.locked = !mi.locked;
      _recalcFillerWeights();
    });
    _persist();
  }

  void _removeRow(MealIngredient mi) {
    setState(() {
      _mainRows.remove(mi);
      _recalcFillerWeights();
    });
    _persist();
  }

  // ─────────────────── UI build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Builder'),
        actions: [
          IconButton(
            tooltip: 'Reset builder',
            icon: const Icon(Icons.refresh),
            onPressed: _resetBuilder,
          ),
          if (_selectedMealType != null &&
              (_mainRows.isNotEmpty || _allFillers.isNotEmpty))
            IconButton(
              tooltip: 'Save meal',
              icon: const Icon(Icons.save),
              onPressed: _showSaveDialog,
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
          final mealTypes = snap.data![1] as List<MealType>;

          return Column(
            children: [
              // Header card: Meal Type + Remaining + Fillers
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Meal Type
                        DropdownButtonFormField<MealType>(
                          initialValue: _selectedMealType,
                          decoration: const InputDecoration(
                            labelText: 'Meal Type',
                          ),
                          items: mealTypes
                              .map(
                                (mt) => DropdownMenuItem(
                                  value: mt,
                                  child: Text(
                                    '${mt.name}  (${_mealTypeRatio(mt)})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (mt) {
                            setState(() {
                              _selectedMealType = mt; // just switch targets
                            });
                            _recalcFillerWeights();
                          },
                        ),

                        // Remaining chips
                        if (_selectedMealType != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _remainChip(
                                'C',
                                _usedCarbsTotal,
                                _selectedMealType!.carbs,
                              ),
                              _remainChip(
                                'P',
                                _usedProteinTotal,
                                _selectedMealType!.protein,
                              ),
                              _remainChip(
                                'F',
                                _usedFatTotal,
                                _selectedMealType!.fat,
                              ),
                            ],
                          ),
                        ],

                        if (_selectedMealType != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Auto fillers',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fillersExpanded = !_fillersExpanded;
                                  });
                                },
                                icon: Icon(
                                  _fillersExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                label: Text(_fillersExpanded ? 'Hide' : 'Show'),
                              ),
                            ],
                          ),
                          if (_fillersExpanded) ...[
                            const SizedBox(height: 8),
                            _fillerPicker(
                              macro: 'C',
                              label: 'Carb filler',
                              current: _fillerCarb?.ingredient,
                              choices: _singleMacro(ingredients, 'C'),
                            ),
                            const SizedBox(height: 8),
                            _fillerPicker(
                              macro: 'P',
                              label: 'Protein filler',
                              current: _fillerProtein?.ingredient,
                              choices: _singleMacro(ingredients, 'P'),
                            ),
                            const SizedBox(height: 8),
                            _fillerPicker(
                              macro: 'F',
                              label: 'Fat filler',
                              current: _fillerFat?.ingredient,
                              choices: _singleMacro(ingredients, 'F'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // autocomplete adder
              if (_selectedMealType != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Autocomplete<Ingredient>(
                    optionsBuilder: (val) => val.text.isEmpty
                        ? const Iterable<Ingredient>.empty()
                        : ingredients.where(
                            (i) => i.name.toLowerCase().contains(
                              val.text.toLowerCase(),
                            ),
                          ),
                    displayStringForOption: (i) => i.name,
                    fieldViewBuilder: (ctx, ctl, focus, _) => TextField(
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
                  key: const PageStorageKey(
                    'meal-scroll',
                  ), // KEEP scroll offset
                  controller: _listController,
                  children: [
                    // Fillers hidden; they still contribute to totals and summary.

                    // Unlocked ---------------------------------------------------------
                    if (_selectedMealType != null &&
                        _unlockedMain.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        child: const Text('Unlocked'),
                      ),
                      ..._unlockedMain.map(
                        (mi) => MealIngredientRow(
                          key: ValueKey(mi),
                          mealIngredient: mi,
                          remainingCarbs: _remainAfterLocked(
                            _selectedMealType!.carbs,
                            _lockedCarbs,
                          ),
                          remainingProtein: _remainAfterLocked(
                            _selectedMealType!.protein,
                            _lockedProtein,
                          ),
                          remainingFat: _remainAfterLocked(
                            _selectedMealType!.fat,
                            _lockedFat,
                          ),
                          editable: true,
                          onChange: _onRowChanged,
                          onDelete: () => _removeRow(mi),
                          onLockToggle: () => _toggleLock(mi),
                        ),
                      ),
                      const Divider(height: 0),
                    ],

                    // Locked -----------------------------------------------------------
                    if (_selectedMealType != null &&
                        _lockedMain.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        child: const Text('Locked'),
                      ),
                      ..._lockedMain.map(
                        (mi) => MealIngredientRow(
                          key: ValueKey(mi),
                          mealIngredient: mi,
                          remainingCarbs: 0,
                          remainingProtein: 0,
                          remainingFat: 0,
                          editable: false,
                          onChange: _onRowChanged,
                          onDelete: () =>
                              _removeRow(mi), // locked rows deletable
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

              // ───── Bottom action bar (Save/Reset) ─────
              if (_selectedMealType != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _showSaveDialog,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Meal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _resetBuilder,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
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
    final rawRemain = tgt - used;
    final remainRounded = double.parse(rawRemain.toStringAsFixed(1));

    final scheme = Theme.of(context).colorScheme;
    final isExact = remainRounded == 0.0;
    final isOver = remainRounded < 0;

    Color background;
    Color foreground;
    String status;

    if (isOver) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      status = '${remainRounded.abs().toStringAsFixed(1)} over';
    } else if (isExact) {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      status = 'On target';
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
      status = '${remainRounded.toStringAsFixed(1)} left';
    }

    final text =
        '$lbl  ${used.toStringAsFixed(1)}/${tgt.toStringAsFixed(1)}  ($status)';

    return Chip(
      label: Text(text),
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _fillerPicker({
    required String macro,
    required String label,
    required Ingredient? current,
    required List<Ingredient> choices,
  }) {
    final key = ValueKey('${macro}_${current?.id ?? 'none'}_${choices.length}');

    return Autocomplete<Ingredient>(
      key: key,
      initialValue: TextEditingValue(text: current?.name ?? ''),
      displayStringForOption: (opt) => opt.name,
      optionsBuilder: (text) {
        final query = text.text.trim().toLowerCase();
        if (query.isEmpty) return choices;
        return choices.where((opt) => opt.name.toLowerCase().contains(query));
      },
      onSelected: (ing) => _chooseFiller(macro, ing),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        final selectedName = current?.name ?? '';
        if (controller.text != selectedName) {
          controller
            ..text = selectedName
            ..selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
        }

        void clearSelection() {
          controller.clear();
          focusNode.unfocus();
          if (current != null) {
            _chooseFiller(macro, null);
          }
        }

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            suffixIcon: (controller.text.isNotEmpty || current != null)
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: clearSelection,
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onEditingComplete: () {
            focusNode.unfocus();
            final typed = controller.text.trim().toLowerCase();
            if (typed.isEmpty) {
              clearSelection();
              return;
            }

            Ingredient? match;
            for (final option in choices) {
              if (option.name.toLowerCase() == typed) {
                match = option;
                break;
              }
            }

            if (match != null) {
              _chooseFiller(macro, match);
            } else {
              controller
                ..text = selectedName
                ..selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, minWidth: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                itemBuilder: (ctx, index) {
                  final option = list[index];
                  return ListTile(
                    dense: true,
                    title: Text(option.name),
                    onTap: () {
                      onSelected(option);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _mealTypeRatio(MealType mt) =>
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
    final fixed2 = value.toStringAsFixed(2);
    if (fixed2.endsWith('.00')) return value.toStringAsFixed(0);
    if (fixed2.endsWith('0')) return value.toStringAsFixed(1);
    return fixed2;
  }

  // ── Meal summary section ─────────────────────────────────────────────
  List<Widget> _summarySection() {
    final rowsInOrder = [..._allFillers, ..._unlockedMain, ..._lockedMain];

    if (rowsInOrder.isEmpty) return [];

    return [
      const Divider(height: 0),
      Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Text('Meal Summary (g)'),
      ),
      ...rowsInOrder.map(
        (mi) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              Text('${mi.weight.toStringAsFixed(1)} g'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mi.ingredient.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }
}
