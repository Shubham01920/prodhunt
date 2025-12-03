import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/user_service.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/notification_service.dart';

class UpvoteService {
  /// ✅ HELPER: Decide collection based on isAI flag
  /// Agar isAI true hai toh 'aiProducts' collection use karega, nahi toh 'products'
  static CollectionReference _getCollection(bool isAI) {
    if (isAI) {
      return FirebaseService.firestore.collection('aiProducts');
    } else {
      return FirebaseService.productsRef; // usually 'products'
    }
  }

  /// ✅ TOGGLE UPVOTE
  /// AI aur Normal dono products ke liye kaam karega
  static Future<bool> toggleUpvote(
    String productId, {
    bool isAI = false,
  }) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return false;

      // 1. Sahi collection select karo
      final collectionRef = _getCollection(isAI);

      DocumentReference upvoteRef = collectionRef
          .doc(productId)
          .collection('upvotes')
          .doc(currentUserId);

      DocumentReference productRef = collectionRef.doc(productId);

      return await FirebaseService.firestore.runTransaction((
        transaction,
      ) async {
        DocumentSnapshot upvoteSnap = await transaction.get(upvoteRef);
        DocumentSnapshot productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw Exception('Product not found');
        }

        Map<String, dynamic> productData =
            productSnap.data() as Map<String, dynamic>;
        int currentUpvotes = productData['upvoteCount'] ?? 0;
        String? productOwnerId = productData['createdBy'];

        if (upvoteSnap.exists) {
          // ❌ Remove upvote (Unlike)
          transaction.delete(upvoteRef);
          transaction.update(productRef, {
            'upvoteCount': (currentUpvotes > 0) ? currentUpvotes - 1 : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false; // Removed
        } else {
          // ✅ Add upvote (Like)
          UserModel? currentUser = await UserService.getCurrentUserProfile();

          transaction.set(upvoteRef, {
            'userId': currentUserId,
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
            'userInfo': {
              'username': currentUser?.username ?? 'Anonymous',
              'displayName': currentUser?.displayName ?? 'Anonymous',
              'profilePicture': currentUser?.profilePicture ?? '',
            },
          });

          transaction.update(productRef, {
            'upvoteCount': currentUpvotes + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 🔔 NOTIFICATION LOGIC (Original)
          // Agar owner exist karta hai aur wo current user nahi hai, toh notification bhejo.
          // AI Products ke liye 'productOwnerId' usually empty hoga, toh ye skip ho jayega.
          if (productOwnerId != null &&
              productOwnerId.isNotEmpty &&
              productOwnerId != currentUserId) {
            await NotificationService.createNotification(
              userId: productOwnerId,
              actorId: currentUserId,
              actorName:
                  currentUser?.displayName ?? currentUser?.username ?? '',
              actorPhoto: currentUser?.profilePicture ?? '',
              productId: productId,
              type: 'upvote',
              message:
                  "${currentUser?.displayName ?? currentUser?.username} upvoted your product",
            );
          }

          return true; // Added
        }
      });
    } catch (e) {
      print('Error toggling upvote: $e');
      return false;
    }
  }

  /// ✅ STREAM: Check if current user has upvoted (Button ka color set karne ke liye)
  static Stream<bool> isUpvotedStream(String productId, {bool isAI = false}) {
    String? currentUserId = FirebaseService.currentUserId;
    if (currentUserId == null) return Stream.value(false);

    return _getCollection(isAI)
        .doc(productId)
        .collection('upvotes')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// ✅ STREAM: Live Upvote Count dikhane ke liye
  static Stream<int> getUpvoteCountStream(
    String productId, {
    bool isAI = false,
  }) {
    return _getCollection(isAI).doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['upvoteCount'] ?? 0;
      }
      return 0;
    });
  }

  // (Optional) Get list of upvoters
  static Stream<List<Map<String, dynamic>>> getProductUpvoters(
    String productId, {
    bool isAI = false,
  }) {
    return _getCollection(isAI)
        .doc(productId)
        .collection('upvotes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
