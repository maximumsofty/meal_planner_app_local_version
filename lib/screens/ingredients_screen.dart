import 'package:flutter/material.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients'),
      ),
      body: const Center(
        child: Text(
          'Ingredients Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
