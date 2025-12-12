import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/model/trending_model.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/widgets/product_card.dart';
import 'package:prodhunt/services/trending_service.dart';
import 'package:prodhunt/services/firebase_service.dart';

class TrendingTab extends StatefulWidget {
  const TrendingTab({super.key});

  @override
  State<TrendingTab> createState() => _TrendingTabState();
}

class _TrendingTabState extends State<TrendingTab> with AutomaticKeepAliveClientMixin {
  // ✅ Active filter state
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'Yesterday', 'Last week', 'Last month'];

  @override
  bool get wantKeepAlive => true;

  /// 🧠 Unified Stream Handler
  /// Switches between "Daily Rankings" (TrendingModel) and "Time Range" Queries (ProductModel)
  Stream<List<ProductModel>> _getTrendingStream(String filter) {
    Stream<List<ProductModel>> rawStream;

    // --- CASE 1: TODAY (Uses TrendingService) ---
    if (filter == 'Today') {
      rawStream = TrendingService.getTodaysTrending().map((trendingModel) {
        if (trendingModel == null) return [];
        // Map TrendingProduct -> ProductModel for the UI
        return trendingModel.topProducts.map((tp) => _mapTrendingToProduct(tp)).toList();
      });
    } 
    
    // --- CASE 2: YESTERDAY (Uses DailyRankings Collection directly) ---
    else if (filter == 'Yesterday') {
      final now = DateTime.now().toUtc();
      final yesterday = now.subtract(const Duration(days: 1));
      final id = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      rawStream = FirebaseService.firestore
          .collection('dailyRankings')
          .doc(id)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return [];
            try {
              final model = TrendingModel.fromFirestore(doc);
              return model.topProducts.map((tp) => _mapTrendingToProduct(tp)).toList();
            } catch (e) {
              return [];
            }
          });
    } 
    
    // --- CASE 3: LAST WEEK / LAST MONTH (Uses Products Collection) ---
    else {
      DateTime startDate;
      if (filter == 'Last week') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else {
        // Last month (approx 30 days)a
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }

      rawStream = FirebaseService.productsRef
          .where('status', isEqualTo: 'published')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .snapshots()
          .map((snap) {
            return snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
          });
    }

    // --- SORTING STEP (Descending Upvotes) ---
    return rawStream.map((unsortedList) {
      final sortedList = List<ProductModel>.from(unsortedList);
      // Sort Descending: b.upvoteCount - a.upvoteCount
      sortedList.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
      return sortedList;
    });
  }

  // Helper to convert TrendingProduct (minimal data) to ProductModel (UI needs)
  ProductModel _mapTrendingToProduct(TrendingProduct tp) {
    return ProductModel(
      productId: tp.productId,
      name: tp.productName,
      tagline: tp.productTagline,
      description: "", // Missing in TrendingProduct
      category: "",    // Missing in TrendingProduct
      createdBy: tp.creatorUsername, // approximate mapping
      logoUrl: tp.productLogo,
      coverUrl: "",    // Missing in TrendingProduct
      source: "", 
      launchDate: tp.productLaunchDate,
      upvoteCount: tp.upvoteCount,
      // Default to 0 as these aren't in the ranking doc
      commentCount: 0, 
      views: 0,
      status: 'published',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ---------------- FILTER & SEARCH BAR ----------------
        _buildSearchFilterRow(screenWidth, cs),

        // ---------------- MAIN CONTENT ----------------
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            // Key ensures stream restarts cleanly when filter changes
            key: ValueKey(_selectedFilter),
            stream: _getTrendingStream(_selectedFilter),
            builder: (context, snap) {
              final isLoading = snap.connectionState == ConnectionState.waiting;

              if (isLoading) return _skeletonList(context);
              if (snap.hasError) return _errorBox(context, 'Failed to load data');

              final items = snap.data ?? [];

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No trending products for $_selectedFilter',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              // Map to ProductUI for the Card
              final uiItems = items.map(ProductUIMapper.fromProductModel).toList();

              return _cardsList(
                uiItems,
                onRefresh: () async {
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _buildSearchFilterRow(double screenWidth, ColorScheme cs) {
    final isSmall = screenWidth < 900;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 0, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: Label + Filter Pills
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Products :',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Filter Pills
                  ..._filters.map((filter) => _buildFilterPill(
                        filter,
                        isActive: _selectedFilter == filter,
                        onTap: () {
                          setState(() => _selectedFilter = filter);
                        },
                      )),
                ],
              ),
            ),
          ),

          // RIGHT: Search Bar + Icons (Hidden on small mobile)
          if (!isSmall) ...[
            const SizedBox(width: 24),

            // Search Bar
            Container(
              width: 260,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    "Search",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // View Icons
            InkWell(
              onTap: () {},
              child: const Icon(Icons.grid_view_rounded, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () {},
              child: const Icon(Icons.view_agenda, color: Colors.black54, size: 24),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, {bool isActive = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEEEEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Cards List (Handles Grid/List responsiveness)
  Widget _cardsList(
    List<ProductUI> items, {
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Mobile List View
          if (width < 900) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => ProductCard(product: items[i]),
            );
          }

          // Desktop Grid View
          final int crossCount = (width / 300).floor().clamp(2, 5);
          final double aspectRatio = crossCount >= 4 ? 0.72 : 0.75;

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 24,
              childAspectRatio: aspectRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => ProductCard(product: items[i]),
          );
        },
      ),
    );
  }

  // Skeleton Loading
  Widget _skeletonList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: cs.surfaceContainerHigh,
        highlightColor: cs.surfaceContainerHighest.withOpacity(0.7),
        period: const Duration(milliseconds: 1200),
        child: const ProductCard.skeleton(),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
    );
  }

  // Error State
  Widget _errorBox(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_tethering_error, color: cs.error),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}