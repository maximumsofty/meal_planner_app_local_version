// lib/services/meal_type_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_type.dart';

/// Service for loading and saving MealType data to Firestore.
class MealTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('mealTypes');
  }

  /// Loads the list of saved MealTypes.
  Future<List<MealType>> loadMealTypes() async {
    if (_userId == null) return [];

    final snapshot = await _collection.get();

    return snapshot.docs
        .map((doc) => MealType.fromJson(doc.data()))
        .toList();
  }

  /// Adds or updates a MealType.
  Future<void> upsertMealType(MealType mealType) async {
    await _collection.doc(mealType.id).set(mealType.toJson());
  }

  /// Deletes a MealType by its id.
  Future<void> deleteMealType(String id) async {
    await _collection.doc(id).delete();
  }

  // Keep for backwards compatibility
  Future<void> saveMealTypes(List<MealType> mealTypes) async {
    final batch = _firestore.batch();
    for (final mealType in mealTypes) {
      batch.set(_collection.doc(mealType.id), mealType.toJson());
    }
    await batch.commit();
  }
}
