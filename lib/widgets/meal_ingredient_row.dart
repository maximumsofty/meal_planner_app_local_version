import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ingredient.dart';
import '../models/meal_ingredient.dart';
import '../utils/responsive_utils.dart';

class MealIngredientRow extends StatefulWidget {
  final MealIngredient mealIngredient;
  final double remainingCarbs;
  final double remainingProtein;
  final double remainingFat;
  final bool editable;
  final VoidCallback onChange;
  final VoidCallback? onDelete;
  final VoidCallback onLockToggle;

  const MealIngredientRow({
    super.key,
    required this.mealIngredient,
    required this.remainingCarbs,
    required this.remainingProtein,
    required this.remainingFat,
    required this.editable,
    required this.onChange,
    required this.onDelete,
    required this.onLockToggle,
  });

  @override
  State<MealIngredientRow> createState() => _MealIngredientRowState();
}

class _MealIngredientRowState extends State<MealIngredientRow> {
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
      if (!_gFocus.hasFocus && widget.editable) {
        _weightSubmit(_gCtl.text);
      }
    };
    _cFocusListener = () {
      if (!_cFocus.hasFocus && widget.editable) {
        _pctSubmit('C', _cPctCtl.text);
      }
    };
    _pFocusListener = () {
      if (!_pFocus.hasFocus && widget.editable) {
        _pctSubmit('P', _pPctCtl.text);
      }
    };
    _fFocusListener = () {
      if (!_fFocus.hasFocus && widget.editable) {
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
  void didUpdateWidget(covariant MealIngredientRow old) {
    super.didUpdateWidget(old);
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
    widget.onChange();
  }

  void _weightSubmit(String v) {
    if (!widget.editable) return;
    final d = double.tryParse(v);
    if (d != null && d > 0)
      _setWeight(d);
    else
      _gCtl.text = mi.weight.toStringAsFixed(1);
  }

  void _pctSubmit(String macro, String v) {
    if (!widget.editable) return;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompactLayout = screenWidth < 380;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: IconButton(
        icon: Icon(mi.locked ? Icons.lock : Icons.lock_open),
        onPressed: widget.onLockToggle,
        tooltip: mi.locked ? 'Unlock' : 'Lock',
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          ing.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: useCompactLayout ? _buildCompactLayout() : _buildNormalLayout(),
      trailing: widget.onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
              tooltip: 'Remove',
            )
          : null,
    );
  }

  /// Compact two-row layout for very narrow screens (< 380px)
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Grams field
        SizedBox(
          width: 140,
          child: TextField(
            controller: _gCtl,
            focusNode: _gFocus,
            enabled: widget.editable,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^[0-9]{0,5}(\\.[0-9]{0,1})?'),
              ),
            ],
            onSubmitted: _weightSubmit,
            onTap: () => _selectAll(_gCtl),
            decoration: const InputDecoration(
              labelText: 'Grams',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Row 2: Percentages + Calories
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _pctField('C', _cPctCtl, ing.carbs == 0, _cFocus, 75),
            _pctField('P', _pPctCtl, ing.protein == 0, _pFocus, 75),
            _pctField('F', _fPctCtl, ing.fat == 0, _fFocus, 75),
            Text(
              'Cal ${mi.calories.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  /// Normal single-row layout for standard screens (>= 380px)
  Widget _buildNormalLayout() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: TextField(
            controller: _gCtl,
            focusNode: _gFocus,
            enabled: widget.editable,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^[0-9]{0,5}(\\.[0-9]{0,1})?'),
              ),
            ],
            onSubmitted: _weightSubmit,
            onTap: () => _selectAll(_gCtl),
            decoration: const InputDecoration(
              labelText: 'Grams',
              isDense: true,
            ),
          ),
        ),
        _pctField('C', _cPctCtl, ing.carbs == 0, _cFocus, 90),
        _pctField('P', _pPctCtl, ing.protein == 0, _pFocus, 90),
        _pctField('F', _fPctCtl, ing.fat == 0, _fFocus, 90),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Cal ${mi.calories.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _pctField(
    String lbl,
    TextEditingController c,
    bool disabled,
    FocusNode focus,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        focusNode: focus,
        enabled: !disabled && widget.editable,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'^[0-9]{0,3}(\\.[0-9]{0,1})?'),
          ),
        ],
        decoration: InputDecoration(labelText: '$lbl %', isDense: true),
        onTap: () => _selectAll(c),
        onSubmitted: (v) => _pctSubmit(lbl, v),
      ),
    );
  }
}
