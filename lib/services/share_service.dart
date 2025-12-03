import 'dart:ui'; // Rect ke liye
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/services/firebase_service.dart';

class ShareService {
  static CollectionReference _getCollection(bool isAI) {
    if (isAI) {
      return FirebaseService.firestore.collection('aiProducts');
    } else {
      return FirebaseService.productsRef;
    }
  }

  static Future<void> shareProduct({
    required String productId,
    required String title,
    required String deepLink,
    bool isAI = false,
    Rect? sharePositionOrigin, // ✅ ADDED THIS PARAMETER
  }) async {
    try {
      // ✅ Pass origin rect to prevent iPad crash
      await Share.share(
        'Check out $title on ProdHunt: $deepLink',
        sharePositionOrigin: sharePositionOrigin,
      );

      final ref = _getCollection(isAI).doc(productId);

      await ref.update({
        'shareCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sharing product: $e");
    }
  }

  static Stream<int> shareCountStream(String productId, {bool isAI = false}) {
    return _getCollection(isAI).doc(productId).snapshots().map((d) {
      if (!d.exists) return 0;
      final data = (d.data() ?? const {}) as Map<String, dynamic>;
      return data['shareCount'] ?? data['shares'] ?? 0;
    });
  }
}
