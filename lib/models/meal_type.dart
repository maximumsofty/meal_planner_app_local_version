// lib/models/meal_type.dart

import 'dart:convert';

/// Represents a meal category (breakfast, lunch, etc.)
/// with default macro targets (in grams).
class MealType {
  final String id;
  String name;
  double carbs; // in grams
  double protein; // in grams
  double fat; // in grams

  MealType({
    required this.id,
    required this.name,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Create a copy with updated fields.
  MealType copyWith({
    String? id,
    String? name,
    double? carbs,
    double? protein,
    double? fat,
  }) {
    return MealType(
      id: id ?? this.id,
      name: name ?? this.name,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MealType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// Convert a MealType into a Map for JSON storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }

  /// Construct a MealType from a JSON Map.
  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'] as String,
      name: json['name'] as String,
      carbs: (json['carbs'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  /// Helper to encode to a JSON string.
  String encode() => jsonEncode(toJson());

  /// Helper to decode from a JSON string.
  static MealType decode(String jsonString) =>
      MealType.fromJson(jsonDecode(jsonString));
}
