// lib/pages/admin_dashboard.dart
// Admin dashboard page for product hunt app.
// Shows quick stats, trending/upvote charts and lists of products
// grouped by status (pending, published, rejected).

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prodhunt/services/firebase_service.dart';

/// Admin overview page used by administrators.
///
/// Displays counts (pending/approved/rejected), a top-trending
/// bar chart (by upvote count), a monthly uploads line chart,
/// and expandable lists for products grouped by status.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Expand/collapse flags for the product lists
  bool showPending = false;
  bool showApproved = false;
  bool showRejected = false;

  // Currently selected year for the monthly uploads chart
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _glassHeader(),

            const SizedBox(height: 18),
            _dashboardStats(),

            const SizedBox(height: 18),
            _trendingProductsGraph(),

            const SizedBox(height: 18),
            _monthlyUploadsGraph(),

            const SizedBox(height: 18),
            _expandSection(
              title: "Pending Products",
              expanded: showPending,
              onTap: () => setState(() => showPending = !showPending),
              child: _pendingList(),
            ),
            const SizedBox(height: 14),
            _expandSection(
              title: "Approved Products",
              expanded: showApproved,
              onTap: () => setState(() => showApproved = !showApproved),
              child: _approvedList(),
            ),
            const SizedBox(height: 14),
            _expandSection(
              title: "Rejected Products",
              expanded: showRejected,
              onTap: () => setState(() => showRejected = !showRejected),
              child: _rejectedList(),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // GLASS HEADER (fixed opacity)
  // -----------------------------------------------------------
  Widget _glassHeader() {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Admin Overview",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Product Hunt Dashboard",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.8), // FIXED
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // STATS
  // -----------------------------------------------------------
  Widget _dashboardStats() {
    return StreamBuilder(
      stream: FirebaseService.productsRef.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final docs = snap.data!.docs;

        // Count documents by status to show quick stats
        int pending = docs.where((d) => d['status'] == 'pending').length;
        int approved = docs.where((d) => d['status'] == 'published').length;
        int rejected = docs.where((d) => d['status'] == 'rejected').length;

        return Row(
          children: [
            Expanded(child: _statCard("Pending", pending, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Approved", approved, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Rejected", rejected, Colors.red)),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TOP TRENDING (real-time)
  // -----------------------------------------------------------
  Widget _trendingProductsGraph() {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔥 Top 7 Trending (Upvotes)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder(
            stream: FirebaseService.productsRef
                .orderBy('upvoteCount', descending: true)
                .limit(7)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox(height: 180);
              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No trending products"),
                );
              }

              return SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),

                    /// X Labels
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            int i = value.toInt();
                            if (i < 0 || i >= docs.length) return Container();
                            return Transform.rotate(
                              angle: -0.8,
                              child: Text(
                                docs[i]['name'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Build bar groups from the snapshot; each bar represents upvote count
                    barGroups: List.generate(docs.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY:
                                double.tryParse("${docs[i]['upvoteCount']}") ??
                                0,
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.deepPurple,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // MONTHLY UPLOAD GRAPH + YEAR SELECTOR
  // -----------------------------------------------------------
  Widget _monthlyUploadsGraph() {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📈 Monthly Uploads",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(5, (i) {
                  int year = DateTime.now().year - i;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() => selectedYear = value!);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          StreamBuilder(
            stream: FirebaseService.productsRef.snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox(height: 180);

              final docs = snap.data!.docs;

              // Aggregate counts per month for the selected year
              List<int> monthly = List.filled(12, 0);

              for (var d in docs) {
                final ts = d['createdAt'];
                if (ts == null) continue; // skip if missing timestamp

                final dt = ts.toDate();
                if (dt.year == selectedYear) {
                  monthly[dt.month - 1]++;
                }
              }

              return SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blueAccent,
                        spots: List.generate(
                          12,
                          (i) => FlSpot(i.toDouble(), monthly[i].toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // EXPANDABLE SECTION
  // -----------------------------------------------------------
  Widget _expandSection({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return _glassContainer(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: child,
            secondChild: const SizedBox(),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // LISTS
  // -----------------------------------------------------------
  // Convenience wrappers for product lists filtered by status
  Widget _pendingList() => _productList("pending", "createdAt");
  Widget _approvedList() => _productList("published", "launchDate");
  Widget _rejectedList() => _productList("rejected", "updatedAt");

  Widget _productList(String status, String orderBy) {
    // Query products by `status` and order by the provided field.
    // Uses the shared `productsRef` from `FirebaseService`.
    final query = FirebaseService.productsRef
        .where('status', isEqualTo: status)
        .orderBy(orderBy, descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Text("Empty"),
          );
        }

        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final productId = d.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading:
                          (data['coverUrl'] != null &&
                              data['coverUrl'].toString().trim().isNotEmpty)
                          ? Image.network(
                              data['coverUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            )
                          : const Icon(Icons.image),

                      title: Text(data['name']),
                      subtitle: Text(data['tagline']),
                    ),

                    // ---------------------------
                    // ADMIN ACTION BUTTONS
                    // ---------------------------
                    if (status == "pending")
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                FirebaseService.productsRef
                                    .doc(productId)
                                    .update({
                                      "status": "published",
                                      "updatedAt": FieldValue.serverTimestamp(),
                                    });
                              },
                              child: const Text("ACCEPT"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                FirebaseService.productsRef
                                    .doc(productId)
                                    .update({
                                      "status": "rejected",
                                      "updatedAt": FieldValue.serverTimestamp(),
                                    });
                              },
                              child: const Text("REJECT"),
                            ),
                          ),
                        ],
                      ),

                    if (status == "rejected")
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                FirebaseService.productsRef
                                    .doc(productId)
                                    .update({
                                      "status": "published",
                                      "updatedAt": FieldValue.serverTimestamp(),
                                    });
                              },
                              child: const Text("PUBLISH AGAIN"),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // GLASS UI CONTAINER
  // -----------------------------------------------------------
  Widget _glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}
