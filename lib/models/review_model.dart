// ============================================================
// REVIEW MODEL
// ============================================================
// Represents a user review for a restaurant.
// Maps to Firestore at: /reviews/{reviewId}
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return ReviewModel(
      id: id,
      restaurantId: map['restaurantId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}