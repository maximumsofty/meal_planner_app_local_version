import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';

class IngredientEditBottomSheet extends StatefulWidget {
  final MealIngredient mealIngredient;
  final double remainingCarbs;
  final double remainingProtein;
  final double remainingFat;
  final VoidCallback onUpdate;
  final VoidCallback? onDelete;
  final VoidCallback onLockToggle;

  const IngredientEditBottomSheet({
    super.key,
    required this.mealIngredient,
    required this.remainingCarbs,
    required this.remainingProtein,
    required this.remainingFat,
    required this.onUpdate,
    required this.onDelete,
    required this.onLockToggle,
  });

  @override
  State<IngredientEditBottomSheet> createState() =>
      _IngredientEditBottomSheetState();
}

class _IngredientEditBottomSheetState
    extends State<IngredientEditBottomSheet> {
  late final TextEditingController _gCtl;
  late final TextEditingController _cPctCtl;
  late final TextEditingController _pPctCtl;
  late final TextEditingController _fPctCtl;
  late final FocusNode _gFocus;
  late final FocusNode _cFocus;
  late final FocusNode _pFocus;
  late final FocusNode _fFocus;
  late final VoidCallback _gFocusListener;
  late final VoidCallback _cFocusListener;
  late final VoidCallback _pFocusListener;
  late final VoidCallback _fFocusListener;

  MealIngredient get mi => widget.mealIngredient;
  Ingredient get ing => mi.ingredient;

  @override
  void initState() {
    super.initState();
    _gCtl = TextEditingController(text: mi.weight.toStringAsFixed(1));
    _cPctCtl = TextEditingController();
    _pPctCtl = TextEditingController();
    _fPctCtl = TextEditingController();
    _gFocus = FocusNode();
    _cFocus = FocusNode();
    _pFocus = FocusNode();
    _fFocus = FocusNode();

    _gFocusListener = () {
      if (!_gFocus.hasFocus) {
        _weightSubmit(_gCtl.text);
      }
    };
    _cFocusListener = () {
      if (!_cFocus.hasFocus) {
        _pctSubmit('C', _cPctCtl.text);
      }
    };
    _pFocusListener = () {
      if (!_pFocus.hasFocus) {
        _pctSubmit('P', _pPctCtl.text);
      }
    };
    _fFocusListener = () {
      if (!_fFocus.hasFocus) {
        _pctSubmit('F', _fPctCtl.text);
      }
    };

    _gFocus.addListener(_gFocusListener);
    _cFocus.addListener(_cFocusListener);
    _pFocus.addListener(_pFocusListener);
    _fFocus.addListener(_fFocusListener);
    _refreshPct();
  }

  @override
  void dispose() {
    _gFocus.removeListener(_gFocusListener);
    _cFocus.removeListener(_cFocusListener);
    _pFocus.removeListener(_pFocusListener);
    _fFocus.removeListener(_fFocusListener);
    _gFocus.dispose();
    _cFocus.dispose();
    _pFocus.dispose();
    _fFocus.dispose();
    _gCtl.dispose();
    _cPctCtl.dispose();
    _pPctCtl.dispose();
    _fPctCtl.dispose();
    super.dispose();
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
    widget.onUpdate();
  }

  void _weightSubmit(String v) {
    final d = double.tryParse(v);
    if (d != null && d > 0) {
      _setWeight(d);
    } else {
      _gCtl.text = mi.weight.toStringAsFixed(1);
    }
  }

  void _pctSubmit(String macro, String v) {
    final pct = double.tryParse(v);
    if (pct == null || pct < 0) return;

    double newW = mi.weight;
    switch (macro) {
      case 'C':
        if (ing.carbs == 0 || widget.remainingCarbs == 0) return;
        newW = (widget.remainingCarbs * pct / 100) / _gPerG(ing.carbs);
        break;
      case 'P':
        if (ing.protein == 0 || widget.remainingProtein == 0) return;
        newW = (widget.remainingProtein * pct / 100) / _gPerG(ing.protein);
        break;
      case 'F':
        if (ing.fat == 0 || widget.remainingFat == 0) return;
        newW = (widget.remainingFat * pct / 100) / _gPerG(ing.fat);
        break;
    }
    _setWeight(newW);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Ingredient name + actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ing.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(mi.locked ? Icons.lock : Icons.lock_open),
                    onPressed: () {
                      widget.onLockToggle();
                      setState(() {});
                    },
                    tooltip: mi.locked ? 'Unlock' : 'Lock',
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete',
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Grams field
              TextFormField(
                controller: _gCtl,
                focusNode: _gFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]{0,5}(\\.[0-9]{0,1})?'),
                  ),
                ],
                onFieldSubmitted: _weightSubmit,
                onTap: () => _selectAll(_gCtl),
                decoration: const InputDecoration(
                  labelText: 'Grams',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 24),

              // Percentage fields
              Text(
                'Macro Percentages',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cPctCtl,
                focusNode: _cFocus,
                enabled: ing.carbs > 0 && widget.remainingCarbs > 0,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]{0,3}(\\.[0-9]{0,1})?'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Carbs %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                onTap: () => _selectAll(_cPctCtl),
                onFieldSubmitted: (v) => _pctSubmit('C', v),
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _pPctCtl,
                focusNode: _pFocus,
                enabled: ing.protein > 0 && widget.remainingProtein > 0,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]{0,3}(\\.[0-9]{0,1})?'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Protein %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                onTap: () => _selectAll(_pPctCtl),
                onFieldSubmitted: (v) => _pctSubmit('P', v),
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _fPctCtl,
                focusNode: _fFocus,
                enabled: ing.fat > 0 && widget.remainingFat > 0,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]{0,3}(\\.[0-9]{0,1})?'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fat %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                onTap: () => _selectAll(_fPctCtl),
                onFieldSubmitted: (v) => _pctSubmit('F', v),
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
