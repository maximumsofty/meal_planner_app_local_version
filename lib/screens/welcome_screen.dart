// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome! Choose where to start:',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),

          // Big Create Meal button
          SizedBox(
            height: 80,
            child: FilledButton.icon(
              onPressed: () => context.go('/create'),
              icon: const Icon(Icons.restaurant_menu, size: 28),
              label: const Text(
                'Create Meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2x2 Grid of other options
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _GridButton(
                  icon: Icons.bookmark,
                  label: 'Saved Meals',
                  onTap: () => context.go('/saved'),
                  colorScheme: colorScheme,
                ),
                _GridButton(
                  icon: Icons.list_alt,
                  label: 'Ingredients',
                  onTap: () => context.go('/ingredients'),
                  colorScheme: colorScheme,
                ),
                _GridButton(
                  icon: Icons.view_list,
                  label: 'Meal Types',
                  onTap: () => context.go('/meal-types'),
                  colorScheme: colorScheme,
                ),
                _GridButton(
                  icon: Icons.swap_horiz,
                  label: 'Reject Swap',
                  onTap: () => context.go('/reject'),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _GridButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
