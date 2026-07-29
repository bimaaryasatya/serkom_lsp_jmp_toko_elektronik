class ReviewModel {
  final int? id;
  final int userId;
  final String userName;
  final int productId;
  final int? transactionId;
  final int rating;
  final String comment;
  final String date;

  ReviewModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    this.transactionId,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      userId: map['userId'] ?? 0,
      userName: map['userName'] ?? 'Pembeli',
      productId: map['productId'] ?? 0,
      transactionId: map['transactionId'],
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'productId': productId,
      'transactionId': transactionId,
      'rating': rating,
      'comment': comment,
    };
  }
}
