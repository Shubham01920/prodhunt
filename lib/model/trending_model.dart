import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingProduct {
  final String productId;
  final int rank;
  final int upvoteCount;
  final String productName;
  final String productTagline;
  final String productLogo;
  final String creatorUsername;
  final DateTime productLaunchDate;

  TrendingProduct({
    required this.productId,
    required this.rank,
    required this.upvoteCount,
    required this.productName,
    required this.productTagline,
    required this.productLogo,
    required this.creatorUsername,
    required this.productLaunchDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'rank': rank,
      'upvoteCount': upvoteCount,
      'productName': productName,
      'productTagline': productTagline,
      'productLogo': productLogo,
      'creatorUsername': creatorUsername,
      'productLaunchDate': Timestamp.fromDate(productLaunchDate),
    };
  }

  factory TrendingProduct.fromMap(Map<String, dynamic> map) {
    return TrendingProduct(
      productId: map['productId'] ?? '',
      rank: (map['rank'] ?? 0).toInt(),
      upvoteCount: (map['upvoteCount'] ?? 0).toInt(),
      productName: map['productName'] ?? '',
      productTagline: map['productTagline'] ?? '',
      productLogo: map['productLogo'] ?? '',
      creatorUsername: map['creatorUsername'] ?? '',
      // ✅ Safety Check for Date
      productLaunchDate: map['productLaunchDate'] is Timestamp
          ? (map['productLaunchDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['productLaunchDate'].toString()) ??
                DateTime.now(),
    );
  }

  // CopyWith helper (Optional but good practice)
  TrendingProduct copyWith({
    String? productId,
    int? rank,
    int? upvoteCount,
    String? productName,
    String? productTagline,
    String? productLogo,
    String? creatorUsername,
    DateTime? productLaunchDate,
  }) {
    return TrendingProduct(
      productId: productId ?? this.productId,
      rank: rank ?? this.rank,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      productName: productName ?? this.productName,
      productTagline: productTagline ?? this.productTagline,
      productLogo: productLogo ?? this.productLogo,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      productLaunchDate: productLaunchDate ?? this.productLaunchDate,
    );
  }
}

class TrendingModel {
  final String trendingId;
  final DateTime date;

  // ✅ Keeps 'topProducts' to satisfy HomePage
  final List<TrendingProduct> topProducts;

  final DateTime generatedAt;
  final String period;
  final int totalProducts;

  TrendingModel({
    required this.trendingId,
    required this.date,
    required this.topProducts,
    required this.generatedAt,
    this.period = 'daily',
    required this.totalProducts,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      // Database mein standard 'products' key se save karenge
      'products': topProducts.map((product) => product.toMap()).toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'period': period,
      'totalProducts': totalProducts,
    };
  }

  // ✅ IMPROVED SAFETY: Checks both 'products' and 'topProducts'
  factory TrendingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<TrendingProduct> products = [];

    // 1. Try reading 'products' (New Standard)
    if (data['products'] != null) {
      products = (data['products'] as List)
          .map((productData) => TrendingProduct.fromMap(productData))
          .toList();
    }
    // 2. Fallback to 'topProducts' (Old Standard)
    else if (data['topProducts'] != null) {
      products = (data['topProducts'] as List)
          .map((productData) => TrendingProduct.fromMap(productData))
          .toList();
    }

    return TrendingModel(
      trendingId: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      topProducts: products, // ✅ Assigned to 'topProducts' variable
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      period: data['period'] ?? 'daily',
      totalProducts: (data['totalProducts'] ?? 0).toInt(),
    );
  }
}