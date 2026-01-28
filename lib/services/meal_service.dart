// lib/services/meal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('meals');
  }

  Future<List<Meal>> loadMeals() async {
    if (_userId == null) return [];

    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Meal.fromJson(doc.data()))
        .toList();
  }

  Future<void> addMeal(Meal meal) async {
    await _collection.doc(meal.id).set(meal.toJson());
  }

  Future<void> upsertMeal(Meal meal) async {
    await _collection.doc(meal.id).set(meal.toJson());
  }

  Future<void> toggleFavorite(String mealId) async {
    final doc = await _collection.doc(mealId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final currentFavorite = data['favorite'] as bool? ?? false;
      await _collection.doc(mealId).update({'favorite': !currentFavorite});
    }
  }

  Future<void> deleteMeal(String mealId) async {
    await _collection.doc(mealId).delete();
  }

  // Keep for backwards compatibility
  Future<void> saveMeals(List<Meal> meals) async {
    final batch = _firestore.batch();
    for (final meal in meals) {
      batch.set(_collection.doc(meal.id), meal.toJson());
    }
    await batch.commit();
  }
}
