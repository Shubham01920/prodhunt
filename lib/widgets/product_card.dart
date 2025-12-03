import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prodhunt/pages/product_details_page.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/upvote_service.dart';
import 'package:prodhunt/services/comment_service.dart';
import 'package:prodhunt/services/save_service.dart';
import 'package:prodhunt/services/share_service.dart';
import 'package:prodhunt/services/view_service.dart';
import 'package:prodhunt/widgets/comment_widget.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});
  final ProductUI product;

  const ProductCard.skeleton({super.key})
    : product = const ProductUI.skeleton();

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _viewRegistered = false;

  // Helper: Check if loading
  bool get _isLoading => widget.product.isSkeleton || widget.product.id.isEmpty;

  Future<void> _registerView() async {
    if (_viewRegistered || _isLoading) return;
    _viewRegistered = true;
    await ViewService.registerView(widget.product.id);
  }

  // ✅ FIX: Safe Share Function
  void _shareProduct(BuildContext ctx) {
    if (_isLoading) return;

    final box = ctx.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final deepLink = 'https://prodhunt.app/p/${widget.product.id}';

    ShareService.shareProduct(
      productId: widget.product.id,
      title: widget.product.name,
      deepLink: deepLink,
      isAI: widget.product.isAI,
      sharePositionOrigin: rect,
    );
  }

  void _openCommentsSheet(BuildContext context) {
    if (_isLoading) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.80,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments • ${widget.product.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Comments List
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      // ✅ Pass isAI
                      child: CommentWidget(
                        productId: widget.product.id,
                        isAI: widget.product.isAI,
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1),

                // ⭐ FIX: Pass isAI to Composer so it saves in correct collection
                _CommentComposer(
                  productId: widget.product.id,
                  isAI: widget.product.isAI,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cs = Theme.of(context).colorScheme;

    void onTapCard() async {
      if (_isLoading) return;
      await _registerView();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(product: widget.product),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: (widget.product.isAI && !_isLoading)
            ? Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BIG IMAGE AREA
          Stack(
            children: [
              GestureDetector(
                onTap: onTapCard,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image:
                        (product.coverUrl != null &&
                            product.coverUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(product.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (product.coverUrl == null || product.coverUrl!.isEmpty)
                      ? Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
              ),

              // AI Badge
              if (widget.product.isAI && !_isLoading)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // BOOKMARK BUTTON
              Positioned(
                top: 16,
                right: 16,
                child: _isLoading
                    ? _staticIconBox(Icons.bookmark_outline)
                    : StreamBuilder<bool>(
                        stream: SaveService.isSaved(product.id),
                        builder: (context, s) {
                          final saved = s.data ?? false;
                          return GestureDetector(
                            onTap: () => SaveService.toggleSave(
                              product.id,
                              isAI: product.isAI,
                            ),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_outline,
                                size: 20,
                                color: saved ? cs.primary : Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // 2. CONTENT AREA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Info
                GestureDetector(
                  onTap: onTapCard,
                  child: Row(
                    children: [
                      _buildCreatorAvatar(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoading
                            ? _skeletonLine(width: 150)
                            : Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                      Text(
                        _isLoading ? "" : product.timeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                if (_isLoading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonLine(width: double.infinity),
                      const SizedBox(height: 6),
                      _skeletonLine(width: 200),
                    ],
                  )
                else if (product.tagline.isNotEmpty)
                  Text(
                    product.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 16),

                // Bottom Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Pill
                    _isLoading
                        ? _skeletonLine(width: 80, height: 24)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (product.tags.isNotEmpty
                                      ? product.tags.first
                                      : product.category)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                    // Actions
                    Row(
                      children: [
                        // Share
                        Builder(
                          builder: (ctx) => _buildSquareButton(
                            icon: Icons.share_outlined,
                            label: "Share",
                            onTap: () => _shareProduct(ctx),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Comments
                        _isLoading
                            ? _staticIconBox(Icons.chat_bubble_outline)
                            : _MetricLive(
                                stream: CommentService.getCommentCount(
                                  product.id,
                                  isAI: product.isAI,
                                ),
                                fallback: product.comments,
                                icon: Icons.chat_bubble_outline,
                                onTap: () => _openCommentsSheet(context),
                              ),

                        const SizedBox(width: 8),

                        // Upvote
                        _isLoading
                            ? _buildSquareButton(
                                icon: Icons.arrow_upward_outlined,
                                label: "0",
                                onTap: () {},
                              )
                            : StreamBuilder<int>(
                                stream: UpvoteService.getUpvoteCountStream(
                                  product.id,
                                  isAI: product.isAI,
                                ),
                                builder: (context, snap) {
                                  final count = snap.data ?? product.upvotes;
                                  return StreamBuilder<bool>(
                                    stream: UpvoteService.isUpvotedStream(
                                      product.id,
                                      isAI: product.isAI,
                                    ),
                                    builder: (context, userSnap) {
                                      final isUpvoted = userSnap.data ?? false;
                                      return _buildSquareButton(
                                        icon: isUpvoted
                                            ? Icons.arrow_upward
                                            : Icons.arrow_upward_outlined,
                                        label: "$count",
                                        isActive: isUpvoted,
                                        onTap: () => UpvoteService.toggleUpvote(
                                          product.id,
                                          isAI: product.isAI,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _staticIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: Colors.black54),
    );
  }

  Widget _buildCreatorAvatar() {
    if (_isLoading) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    if (widget.product.isAI) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
      );
    }
    if (widget.product.creatorId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.person, size: 16, color: Colors.grey),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.usersRef
          .doc(widget.product.creatorId)
          .snapshots(),
      builder: (context, snap) {
        String url = '';
        if (snap.hasData && snap.data!.exists) {
          url = (snap.data!.data()!['profilePicture'] ?? '').toString();
        }
        if (url.isNotEmpty) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildSquareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: Colors.deepOrange) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.deepOrange : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.deepOrange : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({double width = 100, double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Metric Live (Fixed)
class _MetricLive extends StatelessWidget {
  final Stream<int> stream;
  final int fallback;
  final IconData icon;
  final VoidCallback onTap;
  const _MetricLive({
    required this.stream,
    required this.fallback,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? fallback;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ✅ FIXED: Comment Composer now accepts isAI
class _CommentComposer extends StatefulWidget {
  const _CommentComposer({required this.productId, this.isAI = false});
  final String productId;
  final bool isAI;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();
  bool _posting = false;

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    // ✅ PASSING IS AI
    await CommentService.addComment(widget.productId, text, isAI: widget.isAI);
    if (!mounted) return;
    _controller.clear();
    setState(() => _posting = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _posting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _post,
                    icon: const Icon(Icons.send_rounded),
                  ),
          ],
        ),
      ),
    );
  }
}
