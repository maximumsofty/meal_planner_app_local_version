import 'package:flutter/material.dart';

class MealTypesScreen extends StatelessWidget {
  const MealTypesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Types'),
      ),
      body: const Center(
        child: Text(
          'Meal Types Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
