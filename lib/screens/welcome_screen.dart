// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    final gridButtons = [
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
    ];

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome! Choose where to start:',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),

                // Big Create Meal button
                SizedBox(
                  height: 72,
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

                // 4x1 row on wide screens, 2x2 grid on mobile
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: gridButtons
                          .expand((btn) => [
                                Expanded(child: btn),
                                const SizedBox(width: 12),
                              ])
                          .take(gridButtons.length * 2 - 1)
                          .toList(),
                    ),
                  )
                else
                  Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: gridButtons[0]),
                            const SizedBox(width: 16),
                            Expanded(child: gridButtons[1]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: gridButtons[2]),
                            const SizedBox(width: 16),
                            Expanded(child: gridButtons[3]),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }
}
