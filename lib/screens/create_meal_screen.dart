import 'package:flutter/material.dart';

class CreateMealScreen extends StatelessWidget {
  const CreateMealScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meal'),
      ),
      body: const Center(
        child: Text(
          'Create Meal Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
