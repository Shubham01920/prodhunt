import 'package:flutter/material.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/model/trending_model.dart';

/// UI model consumed by ProductCard
class ProductUI {
  final String id;
  final String name;
  final String tagline; // ✅ Added tagline field
  final String category;
  final List<String> tags;

  /// AI generated product?
  final bool isAI;

  /// Cover image
  final String? coverUrl;

  /// Avatar ke liye creatorId (users/uid)
  final String creatorId;

  // metrics
  final int views;
  final int upvotes;
  final int comments;
  final int shares;
  final int saves;

  final String timeAgo;
  final VoidCallback? onMorePressed;
  final bool isSkeleton;

  const ProductUI({
    required this.id,
    required this.name,
    required this.tagline, // ✅ Added to constructor
    required this.category,
    required this.tags,
    required this.coverUrl,
    required this.creatorId,
    required this.views,
    required this.upvotes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.timeAgo,
    required this.isAI,
    this.onMorePressed,
    this.isSkeleton = false,
  });

  /// Skeleton placeholder
  const ProductUI.skeleton()
    : id = '',
      name = '',
      tagline = '', // ✅ Added to skeleton
      category = '',
      tags = const [],
      coverUrl = null,
      creatorId = '',
      views = 0,
      upvotes = 0,
      comments = 0,
      shares = 0,
      saves = 0,
      timeAgo = '',
      onMorePressed = null,
      isSkeleton = true,
      isAI = false; // IMPORTANT: skeleton is NOT AI

  /// Nice label for views
  String get viewsLabel =>
      views >= 1000 ? '${(views / 1000).toStringAsFixed(1)}k' : '$views';
}

/// Mapper from domain → UI model
class ProductUIMapper {
  /// For "All Products" / "Recommendations"
  static ProductUI fromProductModel(ProductModel p) {
    final launched = p.launchDate ?? p.createdAt ?? DateTime.now();

    return ProductUI(
      id: p.productId,
      name: p.name,
      tagline: p.tagline, // ✅ Mapped from ProductModel
      category: p.category,
      tags: p.tags,
      coverUrl: p.coverUrl.isNotEmpty ? p.coverUrl : null,
      creatorId: p.createdBy,
      views: p.views, // Fixed: p.views is int, no need for ?? 0
      upvotes: p.upvoteCount,
      comments: p.commentCount,
      shares: 0,
      saves: 0,
      timeAgo: _timeAgo(launched),

      /// ⭐ Identify AI products
      isAI: p.source == "gemini",

      onMorePressed: () {},
    );
  }

  /// For Trending tab (TrendingModel.topProducts)
  static ProductUI fromTrending(TrendingProduct t) {
    final launched = t.productLaunchDate ?? DateTime.now();

    return ProductUI(
      id: t.productId,
      name: t.productName,
      tagline: t.productTagline ?? "", // ✅ Mapped from Trending (safely)
      category: '—',
      tags: const [],
      coverUrl: null, // trending has no cover
      creatorId: '', // trending has no creator
      views: 0,
      upvotes: t.upvoteCount,
      comments: 0,
      shares: 0,
      saves: 0,
      isAI: false, // trending never AI
      timeAgo: _timeAgo(launched),
      onMorePressed: () {},
    );
  }

  /// Small time-ago helper
  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
