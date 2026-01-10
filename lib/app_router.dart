import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/meal.dart';
import 'screens/create_meal_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/meal_types_screen.dart';
import 'screens/reject_swap_screen.dart';
import 'screens/saved_meals_screen.dart';
import 'screens/welcome_screen.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'welcome',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WelcomeScreen()),
          ),
          GoRoute(
            path: '/create',
            name: 'create',
            pageBuilder: (context, state) {
              final meal = state.extra is Meal ? state.extra as Meal : null;
              return NoTransitionPage(
                child: CreateMealScreen(initialMeal: meal),
              );
            },
          ),
          GoRoute(
            path: '/saved',
            name: 'saved',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SavedMealsScreen()),
          ),
          GoRoute(
            path: '/ingredients',
            name: 'ingredients',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: IngredientsScreen()),
          ),
          GoRoute(
            path: '/meal-types',
            name: 'mealTypes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MealTypesScreen()),
          ),
          GoRoute(
            path: '/reject',
            name: 'rejectSwap',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RejectSwapScreen()),
          ),
        ],
      ),
    ],
  );
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;

  const _NavItem({required this.path, required this.label, required this.icon});
}

const _navItems = [
  _NavItem(path: '/', label: 'Welcome', icon: Icons.home),
  _NavItem(path: '/create', label: 'Create Meal', icon: Icons.restaurant_menu),
  _NavItem(path: '/saved', label: 'Saved Meals', icon: Icons.bookmark),
  _NavItem(path: '/ingredients', label: 'Ingredients', icon: Icons.list_alt),
  _NavItem(path: '/meal-types', label: 'Meal Types', icon: Icons.view_list),
  _NavItem(path: '/reject', label: 'Reject Swap', icon: Icons.swap_horiz),
];

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _currentIndex {
    final match = _navItems.indexWhere((item) {
      if (item.path == '/') return location == '/';
      return location.startsWith(item.path);
    });
    return match >= 0 ? match : 0;
  }

  void _onSelect(BuildContext context, int index) {
    final target = _navItems[index].path;
    if (target != location) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = MediaQuery.of(context).size.width >= 900;
    final centeredChild = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: child,
      ),
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) => _onSelect(context, index),
                labelType: NavigationRailLabelType.all,
                destinations: _navItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(child: centeredChild),
          ],
        ),
      );
    }

    return Scaffold(
      body: centeredChild,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => _onSelect(context, index),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
