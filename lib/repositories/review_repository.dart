import '../database/sqlite_helper.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<Map<String, dynamic>> getProductReviews(int productId) async {
    return _sqliteHelper.getProductReviewSummary(productId);
  }

  Future<Set<String>> getUserReviewedPairs(int userId) async {
    return _sqliteHelper.getUserReviewedPairs(userId);
  }

  Future<bool> addReview(ReviewModel review) async {
    return _sqliteHelper.addReview(review);
  }
}
