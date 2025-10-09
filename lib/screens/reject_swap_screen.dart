import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';
import '../services/ingredient_service.dart';
import '../widgets/meal_ingredient_row.dart';

class RejectSwapScreen extends StatefulWidget {
  const RejectSwapScreen({super.key});

  @override
  State<RejectSwapScreen> createState() => _RejectSwapScreenState();
}

class _RejectSwapScreenState extends State<RejectSwapScreen> {
  final _ingredientService = IngredientService();
  late Future<List<Ingredient>> _ingredientsFuture;
  late final ScrollController _builderScroll;

  final List<MealIngredient> _rejectedRows = [];
  final List<MealIngredient> _mainRows = [];

  MealIngredient? _fillerCarb;
  MealIngredient? _fillerProtein;
  MealIngredient? _fillerFat;
  bool _fillersExpanded = true;
  bool _loadedLastFillers = false;
  bool _draftLoaded = false;
  List<Ingredient> _cachedIngredients = const [];

  static const _draftKey = 'reject_swap_draft';
  static const _lastFillerKeyC = 'reject_last_filler_carb';
  static const _lastFillerKeyP = 'reject_last_filler_protein';
  static const _lastFillerKeyF = 'reject_last_filler_fat';

  @override
  void initState() {
    super.initState();
    _builderScroll = ScrollController();
    _ingredientsFuture = _ingredientService.loadIngredients();
  }

  @override
  void dispose() {
    _builderScroll.dispose();
    super.dispose();
  }

  // ── Reject macros ------------------------------------------------------
  double _sumCarbs(Iterable<MealIngredient> rows) =>
      rows.fold(0, (total, mi) => total + mi.carbs);
  double _sumProtein(Iterable<MealIngredient> rows) =>
      rows.fold(0, (total, mi) => total + mi.protein);
  double _sumFat(Iterable<MealIngredient> rows) =>
      rows.fold(0, (total, mi) => total + mi.fat);

  double get _targetCarbs => _sumCarbs(_rejectedRows);
  double get _targetProtein => _sumProtein(_rejectedRows);
  double get _targetFat => _sumFat(_rejectedRows);

  // ── Replacement builder state -----------------------------------------
  Iterable<MealIngredient> get _lockedMain =>
      _mainRows.where((mi) => mi.locked);
  Iterable<MealIngredient> get _unlockedMain =>
      _mainRows.where((mi) => !mi.locked);

  List<MealIngredient> get _allFillers => [
    if (_fillerCarb != null) _fillerCarb!,
    if (_fillerProtein != null) _fillerProtein!,
    if (_fillerFat != null) _fillerFat!,
  ];

  double get _usedCarbsTotal => _sumCarbs(_mainRows);
  double get _usedProteinTotal => _sumProtein(_mainRows);
  double get _usedFatTotal => _sumFat(_mainRows);

  double _remainAfterLocked(double target, double locked) =>
      max(0, target - locked);

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
    _saveLastFiller(macro, ing);
    _persist();
  }

  void _addMainRow(Ingredient ingredient) {
    setState(() {
      _mainRows.add(
        MealIngredient(
          ingredient: ingredient,
          weight: ingredient.defaultWeight,
        ),
      );
      _recalcFillerWeights();
    });
    _persist();
  }

  void _toggleLock(MealIngredient row) {
    setState(() {
      row.locked = !row.locked;
      _recalcFillerWeights();
    });
    _persist();
  }

  void _removeRow(MealIngredient row) {
    setState(() {
      _mainRows.remove(row);
      _recalcFillerWeights();
    });
    _persist();
  }

  void _onRowChanged() {
    _recalcFillerWeights();
    setState(() {});
    _persist();
  }

  void _recalcFillerWeights() {
    final remCarbs = (_targetCarbs - _sumCarbs(_mainRows))
        .clamp(0.0, double.infinity)
        .toDouble();
    final remProtein = (_targetProtein - _sumProtein(_mainRows))
        .clamp(0.0, double.infinity)
        .toDouble();
    final remFat = (_targetFat - _sumFat(_mainRows))
        .clamp(0.0, double.infinity)
        .toDouble();

    void setWeight(MealIngredient? mi, double remaining, double gramsPerGram) {
      if (mi == null || gramsPerGram == 0.0) return;
      mi.weight = double.parse((remaining / gramsPerGram).toStringAsFixed(1));
    }

    setWeight(
      _fillerCarb,
      remCarbs,
      _fillerCarb == null
          ? 0.0
          : _fillerCarb!.ingredient.carbs /
                _fillerCarb!.ingredient.defaultWeight,
    );

    setWeight(
      _fillerProtein,
      remProtein,
      _fillerProtein == null
          ? 0.0
          : _fillerProtein!.ingredient.protein /
                _fillerProtein!.ingredient.defaultWeight,
    );

    setWeight(
      _fillerFat,
      remFat,
      _fillerFat == null
          ? 0.0
          : _fillerFat!.ingredient.fat / _fillerFat!.ingredient.defaultWeight,
    );
  }

  void _persist() {
    _saveDraft();
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'rejected': _rejectedRows
          .map(
            (mi) => {'ingredient': mi.ingredient.toJson(), 'weight': mi.weight},
          )
          .toList(),
      'replacement': _mainRows
          .map(
            (mi) => {
              'ingredient': mi.ingredient.toJson(),
              'weight': mi.weight,
              'locked': mi.locked,
            },
          )
          .toList(),
      'fillers': {
        'c': _fillerCarb?.ingredient.toJson(),
        'p': _fillerProtein?.ingredient.toJson(),
        'f': _fillerFat?.ingredient.toJson(),
      },
      'fillersExpanded': _fillersExpanded,
    };
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  Future<void> _loadDraft(List<Ingredient> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) {
      await _loadSavedFillers(ingredients);
      return;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;

    Ingredient resolve(Map<String, dynamic> json) {
      final id = json['id'] as String?;
      final match = ingredients.where((ing) => ing.id == id);
      if (match.isNotEmpty) return match.first;
      return Ingredient.fromJson(json);
    }

    setState(() {
      _rejectedRows
        ..clear()
        ..addAll(
          (data['rejected'] as List<dynamic>).map((item) {
            final map = item as Map<String, dynamic>;
            final ing = resolve(map['ingredient'] as Map<String, dynamic>);
            return MealIngredient(
              ingredient: ing,
              weight: (map['weight'] as num).toDouble(),
            );
          }),
        );

      _mainRows
        ..clear()
        ..addAll(
          (data['replacement'] as List<dynamic>).map((item) {
            final map = item as Map<String, dynamic>;
            final ing = resolve(map['ingredient'] as Map<String, dynamic>);
            final mi = MealIngredient(
              ingredient: ing,
              weight: (map['weight'] as num).toDouble(),
            );
            mi.locked = map['locked'] as bool? ?? false;
            return mi;
          }),
        );

      Ingredient? toIngredient(Map<String, dynamic>? json) =>
          json == null ? null : resolve(json);
      final fillers = (data['fillers'] as Map<String, dynamic>?) ?? const {};
      final c = toIngredient(fillers['c'] as Map<String, dynamic>?);
      final p = toIngredient(fillers['p'] as Map<String, dynamic>?);
      final f = toIngredient(fillers['f'] as Map<String, dynamic>?);

      _fillerCarb = c == null
          ? null
          : (MealIngredient(ingredient: c, weight: 0)..locked = true);
      _fillerProtein = p == null
          ? null
          : (MealIngredient(ingredient: p, weight: 0)..locked = true);
      _fillerFat = f == null
          ? null
          : (MealIngredient(ingredient: f, weight: 0)..locked = true);

      _fillersExpanded = data['fillersExpanded'] as bool? ?? true;
      _loadedLastFillers = true;
      _recalcFillerWeights();
    });
  }

  Future<void> _resetSwap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset reject swap?'),
        content: const Text(
          'This will remove all rejected items, replacement ingredients, and current filler selections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _rejectedRows.clear();
      _mainRows.clear();
      _fillerCarb = null;
      _fillerProtein = null;
      _fillerFat = null;
      _fillersExpanded = true;
    });
    _recalcFillerWeights();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);

    _draftLoaded = false;
    _loadedLastFillers = false;
    if (_cachedIngredients.isNotEmpty) {
      await _loadSavedFillers(_cachedIngredients);
    } else {
      _persist();
    }
  }

  // ── Rejects helpers ----------------------------------------------------
  void _addRejected(Ingredient ingredient) {
    if (!mounted) return;

    setState(() {
      _rejectedRows.add(
        MealIngredient(
          ingredient: ingredient,
          weight: ingredient.defaultWeight,
        ),
      );
      _recalcFillerWeights();
    });
    _persist();
  }

  void _updateRejectedWeight(MealIngredient row, double weight) {
    setState(() {
      row.weight = weight;
      _recalcFillerWeights();
    });
    _persist();
  }

  void _removeRejected(MealIngredient row) {
    setState(() {
      _rejectedRows.remove(row);
      _recalcFillerWeights();
    });
    _persist();
  }

  Future<void> _loadSavedFillers(List<Ingredient> ingredients) async {
    if (_loadedLastFillers) return;
    _loadedLastFillers = true;
    final prefs = await SharedPreferences.getInstance();
    Ingredient? find(String? id) {
      if (id == null) return null;
      for (final ing in ingredients) {
        if (ing.id == id) return ing;
      }
      return null;
    }

    final c = find(prefs.getString(_lastFillerKeyC));
    final p = find(prefs.getString(_lastFillerKeyP));
    final f = find(prefs.getString(_lastFillerKeyF));

    if (!mounted) return;
    setState(() {
      _fillerCarb = c == null
          ? null
          : (MealIngredient(ingredient: c, weight: 0)..locked = true);
      _fillerProtein = p == null
          ? null
          : (MealIngredient(ingredient: p, weight: 0)..locked = true);
      _fillerFat = f == null
          ? null
          : (MealIngredient(ingredient: f, weight: 0)..locked = true);
      _recalcFillerWeights();
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reject Swap'),
        actions: [
          IconButton(
            tooltip: 'Reset swap',
            icon: const Icon(Icons.refresh),
            onPressed: _resetSwap,
          ),
        ],
      ),
      body: FutureBuilder<List<Ingredient>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ingredients = snapshot.data ?? [];
          _cachedIngredients = List<Ingredient>.from(ingredients);
          if (!_draftLoaded) {
            _draftLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadDraft(List<Ingredient>.from(ingredients));
            });
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _rejectedCard(ingredients),
              const SizedBox(height: 16),
              _builderCard(ingredients),
            ],
          );
        },
      ),
    );
  }

  Widget _rejectedCard(List<Ingredient> ingredients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejected Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _targetChip('C', _targetCarbs),
                _targetChip('P', _targetProtein),
                _targetChip('F', _targetFat),
              ],
            ),
            const SizedBox(height: 12),
            if (_rejectedRows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No rejected ingredients recorded yet.'),
              )
            else
              ..._rejectedRows.map(
                (row) => _RejectedRow(
                  key: ValueKey('reject-${row.ingredient.id}-${row.weight}'),
                  mealIngredient: row,
                  onWeightChanged: (value) => _updateRejectedWeight(row, value),
                  onRemove: () => _removeRejected(row),
                ),
              ),
            const SizedBox(height: 12),
            _ingredientAutocomplete(
              label: 'Add rejected ingredient',
              ingredients: ingredients,
              onSelected: _addRejected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _builderCard(List<Ingredient> ingredients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replacement Meal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _comparisonChip('C', _usedCarbsTotal, _targetCarbs),
                _comparisonChip('P', _usedProteinTotal, _targetProtein),
                _comparisonChip('F', _usedFatTotal, _targetFat),
              ],
            ),
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
                    _persist();
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
            const SizedBox(height: 12),
            _ingredientAutocomplete(
              label: 'Add replacement ingredient',
              ingredients: ingredients,
              onSelected: _addMainRow,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Scrollbar(
                controller: _builderScroll,
                child: ListView(
                  controller: _builderScroll,
                  shrinkWrap: true,
                  children: [
                    if (_unlockedMain.isNotEmpty) ...[
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
                            _targetCarbs,
                            _sumCarbs(_lockedMain),
                          ),
                          remainingProtein: _remainAfterLocked(
                            _targetProtein,
                            _sumProtein(_lockedMain),
                          ),
                          remainingFat: _remainAfterLocked(
                            _targetFat,
                            _sumFat(_lockedMain),
                          ),
                          editable: true,
                          onChange: _onRowChanged,
                          onDelete: () => _removeRow(mi),
                          onLockToggle: () => _toggleLock(mi),
                        ),
                      ),
                      const Divider(height: 0),
                    ],
                    if (_lockedMain.isNotEmpty) ...[
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
                          onDelete: () => _removeRow(mi),
                          onLockToggle: () => _toggleLock(mi),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ..._summarySection(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientAutocomplete({
    required String label,
    required List<Ingredient> ingredients,
    required ValueChanged<Ingredient> onSelected,
  }) {
    return Autocomplete<Ingredient>(
      optionsBuilder: (text) {
        if (text.text.isEmpty) return ingredients;
        final query = text.text.toLowerCase();
        return ingredients.where(
          (ingredient) => ingredient.name.toLowerCase().contains(query),
        );
      },
      displayStringForOption: (option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
      onSelected: onSelected,
    );
  }

  Widget _targetChip(String label, double value) {
    return Chip(label: Text('$label ${value.toStringAsFixed(1)} g'));
  }

  Widget _comparisonChip(String label, double used, double target) {
    final diff = target - used;
    final roundedDiff = double.parse(diff.toStringAsFixed(1));

    final scheme = Theme.of(context).colorScheme;
    late Color background;
    late Color foreground;
    late String status;

    if (roundedDiff < 0) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      status = '${roundedDiff.abs().toStringAsFixed(1)} over';
    } else if (roundedDiff == 0) {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      status = 'On target';
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
      status = '${roundedDiff.toStringAsFixed(1)} left';
    }

    final text =
        '$label  ${used.toStringAsFixed(1)}/${target.toStringAsFixed(1)}  ($status)';

    return Chip(
      label: Text(text),
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
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

  List<Widget> _summarySection() {
    final rowsInOrder = [..._allFillers, ..._unlockedMain, ..._lockedMain];

    if (rowsInOrder.isEmpty) return [];

    return [
      const Divider(height: 0),
      Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Text('Replacement Summary (g)'),
      ),
      ...rowsInOrder.map(
        (mi) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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

class _RejectedRow extends StatefulWidget {
  final MealIngredient mealIngredient;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onRemove;

  const _RejectedRow({
    required super.key,
    required this.mealIngredient,
    required this.onWeightChanged,
    required this.onRemove,
  });

  @override
  State<_RejectedRow> createState() => _RejectedRowState();
}

class _RejectedRowState extends State<_RejectedRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  MealIngredient get mi => widget.mealIngredient;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: mi.weight.toStringAsFixed(1));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commit();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed == null || parsed <= 0) {
      _controller.text = mi.weight.toStringAsFixed(1);
      return;
    }
    widget.onWeightChanged(parsed);
    _controller.text = parsed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mi.ingredient.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]{0,5}(\.[0-9]{0,1})?'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Weight (g)',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _commit(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _macroText('C', mi.carbs),
                        _macroText('P', mi.protein),
                        _macroText('F', mi.fat),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroText(String label, double value) {
    return Text('$label ${value.toStringAsFixed(1)} g');
  }
}
