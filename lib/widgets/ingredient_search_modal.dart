import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientSearchModal extends StatefulWidget {
  final List<Ingredient> ingredients;
  final String title;

  const IngredientSearchModal({
    super.key,
    required this.ingredients,
    this.title = 'Add Ingredient',
  });

  @override
  State<IngredientSearchModal> createState() => _IngredientSearchModalState();
}

class _IngredientSearchModalState extends State<IngredientSearchModal> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  List<Ingredient> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _filteredIngredients = widget.ingredients;

    // Auto-focus search field when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });

    _searchController.addListener(_filterIngredients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _filterIngredients() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = widget.ingredients;
      } else {
        _filteredIngredients = widget.ingredients
            .where((ing) => ing.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Search ingredients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocus.requestFocus();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body: _filteredIngredients.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'Start typing to search'
                    : 'No ingredients found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            )
          : ListView.builder(
              itemCount: _filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _filteredIngredients[index];
                return _buildIngredientTile(ingredient);
              },
            ),
    );
  }

  Widget _buildIngredientTile(Ingredient ingredient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.pop(context, ingredient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ingredient.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Per ${ingredient.defaultWeight.toStringAsFixed(0)}g:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _macroChip(
                    'Carbs',
                    ingredient.carbs.toStringAsFixed(1),
                    Colors.blue,
                  ),
                  _macroChip(
                    'Protein',
                    ingredient.protein.toStringAsFixed(1),
                    Colors.green,
                  ),
                  _macroChip(
                    'Fat',
                    ingredient.fat.toStringAsFixed(1),
                    Colors.orange,
                  ),
                  _macroChip(
                    'Cal',
                    ingredient.calories.toStringAsFixed(0),
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${value}g',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }
}
