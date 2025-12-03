import 'package:flutter/material.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/view_service.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/widgets/comment_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductUI product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? _websiteUrl;
  String? _fullDescription;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    // 1. Register View (Increase View Count)
    ViewService.registerView(widget.product.id);

    // 2. Fetch Full Details (Website URL & Description)
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    try {
      // Check collection based on AI flag
      final collection = widget.product.isAI ? 'aiProducts' : 'products';

      final doc = await FirebaseService.firestore
          .collection(collection)
          .doc(widget.product.id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _websiteUrl = data['website'];
          _fullDescription = data['description'];
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print("Error fetching details: $e");
      setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _launchWebsite() async {
    if (_websiteUrl == null || _websiteUrl!.isEmpty) return;
    final uri = Uri.parse(_websiteUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.product;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // --- 1. Large App Bar with Image ---
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: p.coverUrl ?? p.id,
                    child: p.coverUrl != null && p.coverUrl!.isNotEmpty
                        ? Image.network(p.coverUrl!, fit: BoxFit.cover)
                        : Container(color: cs.surfaceContainerHighest),
                  ),
                  // Gradient Shade for text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. Content Body ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & AI Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (p.isAI)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: const Text(
                            "AI Generated",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.tagline,
                    style: TextStyle(
                      fontSize: 18,
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons (Visit Website)
                  // if (_isLoadingDetails)
                  //   const LinearProgressIndicator()
                  // else if (_websiteUrl != null && _websiteUrl!.isNotEmpty)
                  //   SizedBox(
                  //     width: double.infinity,
                  //     child: ElevatedButton.icon(
                  //       style: ElevatedButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(vertical: 16),
                  //         backgroundColor: cs.primary,
                  //         foregroundColor: cs.onPrimary,
                  //       ),
                  //       onPressed: _launchWebsite,
                  //       icon: const Icon(Icons.public),
                  //       label: const Text("VISIT WEBSITE"),
                  //     ),
                  //   ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // About Section
                  Text(
                    "About this product",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingDetails
                      ? const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Text(
                          _fullDescription ?? "No description available.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: cs.onSurface.withOpacity(0.8),
                          ),
                        ),

                  const SizedBox(height: 32),
                  const Divider(),

                  // Comments Header
                  const SizedBox(height: 16),
                  Text(
                    "Discussion",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 3. Comments List (Using existing widget logic) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CommentWidget(
                productId: p.id,
              ), // Your existing comment widget
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
