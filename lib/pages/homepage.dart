import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/ads/ads_service/banner_ad_widget.dart';
import 'package:prodhunt/ads/helper/trending_tab.dart';
import 'package:prodhunt/pages/activity_page.dart';
import 'package:prodhunt/pages/advertise.dart';
import 'package:prodhunt/pages/news_page.dart';
import 'package:prodhunt/pages/notification_page.dart';
import 'package:prodhunt/pages/profile_page.dart';
import 'package:prodhunt/widgets/category_picker.dart';
import 'package:shimmer/shimmer.dart';

import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/widgets/product_card.dart';
import 'package:prodhunt/widgets/side_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb && screenWidth > 800;

    return AnimatedSideDrawer(
      child: Scaffold(
        backgroundColor: isDesktop ? const Color(0xFFFAFAFA) : cs.surface,

        // APP BAR LOGIC
        appBar: isDesktop
            ? _buildDesktopAppBar(context)
            : _buildMobileAppBar(context, cs),

        body: Column(
          children: [
            // Desktop TabBar
            if (isDesktop) _buildDesktopTabBar(cs),

            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      // ✅ 1. Call the new external TrendingTab
                      const TrendingTab(), 

                      // 2. Other tabs remain defined below
                      const _RecommendationsTab(),
                      const _AllProductsTab(),
                      const _AiProductsTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: kIsWeb ? null : const BannerAdWidget(),
      ),
    );
  }

  // ---------------- MOBILE APP BAR ----------------
  PreferredSizeWidget _buildMobileAppBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.openDrawer(),
        ),
      ),
      backgroundColor: cs.surface,
      elevation: 0,
      titleSpacing: 16,
      title: Text(
        'Prod Hunt',
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: 4),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: cs.secondaryContainer,
            child: Icon(Icons.person, color: cs.onSecondaryContainer),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            tabs: const [
              Tab(text: 'Trending'),
              Tab(text: 'Recommendations'),
              Tab(text: 'All Products'),
              Tab(text: 'AI'),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- DESKTOP APP BAR ----------------
  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1440),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "logo",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 32),

                // Links
                _desktopNavLink("Launches", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                }),
                _desktopNavLink("Categories", onTap: () {
                    showProductHuntCategoryPicker(
                      context,
                      onSelected: (category, subCategory) {
                        print("Selected → $category → $subCategory");
                      },
                    );
                }),
                _desktopNavLink("News", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NewsPage()));
                }),
                _desktopNavLink("Forums", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityPage()));
                }),
                _desktopNavLink("Advertise", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdvertisePage()));
                }),

                const Spacer(),

                // Right Actions
                ElevatedButton.icon(
                  onPressed: () {}, // TODO: Open Submit Modal
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 20),

                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
                  },
                  icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 8),

                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopNavLink(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Desktop TabBar
  Widget _buildDesktopTabBar(ColorScheme cs) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1440),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Recommendations'),
            Tab(text: 'All Products'),
            Tab(text: 'AI'),
          ],
        ),
      ),
    );
  }
}

// ❌ Removed duplicate _TrendingTab class here (replaced by import)

/* ---------------- RECOMMENDATIONS (Keep-Alive) ---------------- */

class _RecommendationsTab extends StatefulWidget {
  const _RecommendationsTab();
  @override
  State<_RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<_RecommendationsTab> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userQuery = FirebaseService.productsRef
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(20);

    final aiQuery = FirebaseService.firestore
        .collection('aiProducts')
        .orderBy('createdAt', descending: true)
        .limit(10);

    return StreamBuilder<QuerySnapshot>(
      stream: userQuery.snapshots(includeMetadataChanges: true),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return _skeletonList(context);

        return StreamBuilder<QuerySnapshot>(
          stream: aiQuery.snapshots(includeMetadataChanges: true),
          builder: (context, aiSnap) {
            final List<ProductUI> list = [];

            // User Products
            if (userSnap.hasData) {
              list.addAll(
                userSnap.data!.docs
                    .map((d) => ProductModel.fromFirestore(d))
                    .map(ProductUIMapper.fromProductModel)
                    .toList(),
              );
            }

            // AI Products
            if (aiSnap.hasData) {
              list.addAll(
                aiSnap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ProductUI(
                    id: d.id,
                    name: data['name'] ?? "AI Product",
                    tagline: data['tagline'] ?? "Futuristic Tech",
                    category: "AI Generated",
                    tags: const [],
                    coverUrl: data['image'] ?? "",
                    creatorId: "",
                    upvotes: data['upvoteCount'] ?? 0,
                    views: data['views'] ?? 0,
                    comments: 0,
                    shares: 0,
                    saves: 0,
                    timeAgo: "Just now",
                    isAI: true,
                    onMorePressed: () {},
                  );
                }).toList(),
              );
            }

            if (list.isEmpty) return const Center(child: Text("No recommendations yet"));

            return _cardsList(
              list,
              onRefresh: () async {
                await userQuery.get(const GetOptions(source: Source.server));
                await aiQuery.get(const GetOptions(source: Source.server));
              },
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- ALL PRODUCTS (Keep-Alive) ---------------- */

class _AllProductsTab extends StatefulWidget {
  const _AllProductsTab();
  @override
  State<_AllProductsTab> createState() => _AllProductsTabState();
}

class _AllProductsTabState extends State<_AllProductsTab> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final query = FirebaseService.productsRef
        .where('status', isEqualTo: 'published')
        .orderBy('launchDate', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        final isLoading = snap.connectionState == ConnectionState.waiting || !snap.hasData;

        if (isLoading) return _skeletonList(context);
        if (snap.hasError) return _errorBox(context, 'Failed to load products');
        if (snap.data!.docs.isEmpty) return const Center(child: Text('No products'));

        final items = snap.data!.docs
            .map((d) => ProductModel.fromFirestore(d))
            .map(ProductUIMapper.fromProductModel)
            .toList();

        return _cardsList(
          items,
          onRefresh: () async {
            await query.get(const GetOptions(source: Source.server));
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- AI PRODUCTS (Keep-Alive) ---------------- */

class _AiProductsTab extends StatefulWidget {
  const _AiProductsTab();
  @override
  State<_AiProductsTab> createState() => _AiProductsTabState();
}

class _AiProductsTabState extends State<_AiProductsTab> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final query = FirebaseService.firestore
        .collection('aiProducts')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        if (!snap.hasData || snap.connectionState == ConnectionState.waiting) {
          return _skeletonList(context);
        }
        if (snap.hasError) return _errorBox(context, 'Failed to load AI products');

        final now = DateTime.now();
        final docs = snap.data!.docs;

        // Auto hide products older than 24 hours
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data['createdAt'];
          if (ts is! Timestamp) return false;
          return now.difference(ts.toDate()).inHours < 24;
        }).toList();

        if (filtered.isEmpty) return const Center(child: Text("No AI products"));

        final items = filtered.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return ProductUI(
            id: d.id,
            name: data['name'] ?? "AI Product",
            tagline: data['tagline'] ?? "Futuristic Tech",
            category: "AI Generated",
            tags: const [],
            coverUrl: data['image'] ?? "",
            creatorId: "",
            views: 0,
            upvotes: 0,
            comments: 0,
            shares: 0,
            saves: 0,
            timeAgo: _aiTimeAgo(data['createdAt']),
            isAI: true,
            onMorePressed: () {},
          );
        }).toList();

        return _cardsList(
          List<ProductUI>.from(items),
          onRefresh: () async {
            await query.get(const GetOptions(source: Source.server));
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// ---------------- SHARED HELPERS (Used by tabs other than Trending) ----------------

String _aiTimeAgo(dynamic ts) {
  if (ts == null) return "Just now";
  if (ts is Timestamp) {
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  return "Just now";
}

Widget _cardsList(List<ProductUI> items, {required Future<void> Function() onRefresh}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 900) {
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
                child: ProductCard(product: items[i]),
              );
            },
          );
        }
        final int crossCount = (width / 300).floor().clamp(2, 5);
        final double aspectRatio = crossCount >= 4 ? 0.72 : 0.75;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
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

Widget _skeletonList(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          onPressed: () => {},
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}