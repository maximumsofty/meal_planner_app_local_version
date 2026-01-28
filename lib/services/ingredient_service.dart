// lib/services/ingredient_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ingredient.dart';
import '../data/default_ingredients.dart';

/// Service for loading and saving Ingredient data to Firestore.
class IngredientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('ingredients');
  }

  /// Loads the list of saved Ingredients.
  /// If none exist, seeds from [defaultIngredients] and returns them.
  Future<List<Ingredient>> loadIngredients() async {
    if (_userId == null) return [];

    final snapshot = await _collection.get();

    if (snapshot.docs.isEmpty) {
      // First run: seed defaults
      await _seedDefaults();
      return defaultIngredients;
    }

    return snapshot.docs
        .map((doc) => Ingredient.fromJson(doc.data()))
        .toList();
  }

  /// Seeds default ingredients for new users
  Future<void> _seedDefaults() async {
    final batch = _firestore.batch();
    for (final ingredient in defaultIngredients) {
      batch.set(_collection.doc(ingredient.id), ingredient.toJson());
    }
    await batch.commit();
  }

  /// Saves a single ingredient (used for batch operations)
  Future<void> saveIngredient(Ingredient ingredient) async {
    await _collection.doc(ingredient.id).set(ingredient.toJson());
  }

  /// Adds or updates an Ingredient.
  Future<void> upsertIngredient(Ingredient ingredient) async {
    await _collection.doc(ingredient.id).set(ingredient.toJson());
  }

  /// Deletes an Ingredient by its id.
  Future<void> deleteIngredient(String id) async {
    await _collection.doc(id).delete();
  }

  /// Overwrite saved ingredients with the built-in defaults.
  Future<void> resetToDefaults() async {
    // Delete all existing
    final snapshot = await _collection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Seed defaults
    await _seedDefaults();
  }

  // Keep this for backwards compatibility, but it's not used with Firestore
  Future<void> saveIngredients(List<Ingredient> ingredients) async {
    final batch = _firestore.batch();
    for (final ingredient in ingredients) {
      batch.set(_collection.doc(ingredient.id), ingredient.toJson());
    }
    await batch.commit();
  }
}
