import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String filamentId;
  final String reviewText;
  final double rating;
  final String? imageUrl;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.filamentId,
    required this.reviewText,
    required this.rating,
    this.imageUrl,
    required this.timestamp,
  });

  // Factory constructor to create a ReviewModel from Firestore data
  factory ReviewModel.fromMap(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      userId: data['userId'] ?? '',
      filamentId: data['filamentId'] ?? '',
      reviewText: data['reviewText'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Method to convert ReviewModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'filamentId': filamentId,
      'reviewText': reviewText,
      'rating': rating,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}
