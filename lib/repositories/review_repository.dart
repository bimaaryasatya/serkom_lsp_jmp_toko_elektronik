import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/review_model.dart';

class ReviewRepository {
  Future<Map<String, dynamic>> getProductReviews(int productId) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/reviews/$productId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['reviews'] ?? [];
        final reviews = list.map((e) => ReviewModel.fromMap(Map<String, dynamic>.from(e))).toList();
        return {
          'reviews': reviews,
          'avgRating': (data['avgRating'] as num).toDouble(),
          'count': data['count'] ?? 0,
        };
      }
      return {'reviews': <ReviewModel>[], 'avgRating': 0.0, 'count': 0};
    } catch (_) {
      return {'reviews': <ReviewModel>[], 'avgRating': 0.0, 'count': 0};
    }
  }

  Future<Set<String>> getUserReviewedPairs(int userId) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/reviews/user/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pairs = data['reviewedPairs'] ?? [];
        return pairs.map((e) => e.toString()).toSet();
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(review.toMap()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
