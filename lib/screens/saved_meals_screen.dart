import 'package:flutter/material.dart';

class SavedMealsScreen extends StatelessWidget {
  const SavedMealsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Meals'),
      ),
      body: const Center(
        child: Text(
          'Saved Meals Library',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
