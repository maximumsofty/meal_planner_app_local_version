// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import the screens you want to navigate to

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // helper to avoid repeating boilerplate
    ElevatedButton navButton(String label, String path) => ElevatedButton.icon(
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => context.go(path),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Keto Meal Planner')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome! Choose where to start:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            navButton('Create Meal', '/create'),
            navButton('Saved Meals', '/saved'), // NEW
            navButton('Ingredients', '/ingredients'),
            navButton('Meal Types', '/meal-types'),
            navButton('Reject Swap', '/reject'),
          ],
        ),
      ),
    );
  }
}
