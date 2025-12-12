import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prodhunt/model/comment_model.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/user_service.dart';
import 'package:prodhunt/services/notification_service.dart';

class CommentService {
  /// ✅ HELPER: Choose correct collection based on isAI flag
  static CollectionReference _getCollection(bool isAI) {
    if (isAI) {
      return FirebaseService.firestore.collection('aiProducts');
    } else {
      return FirebaseService.productsRef;
    }
  }

  /* ---------------- Add comment (parent or reply) ---------------- */
  static Future<String?> addComment(
    String productId,
    String content, {
    String? parentCommentId,
    bool isAI = false, // ⭐ Added isAI param
  }) async {
    try {
      final currentUserId = FirebaseService.currentUserId;
      // ✅ Safety Check: Empty ID par return karo
      if (currentUserId == null || productId.isEmpty) return null;

      final currentUser = await UserService.getCurrentUserProfile();
      if (currentUser == null) return null;

      final comment = CommentModel(
        commentId: '',
        userId: currentUserId,
        productId: productId,
        content: content.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: parentCommentId,
        userInfo: {
          'username': currentUser.username,
          'displayName': currentUser.displayName,
          'profilePicture': currentUser.profilePicture,
        },
        upvotes: 0,
        repliesCount: 0,
        isEdited: false,
        isDeleted: false,
      );

      // ✅ Use Dynamic Collection
      final productDoc = _getCollection(isAI).doc(productId);

      // Add comment to subcollection
      final ref = await productDoc.collection('comments').add(comment.toMap());

      // Update counts
      await productDoc.update({'commentCount': FieldValue.increment(1)});

      if (parentCommentId != null) {
        await productDoc.collection('comments').doc(parentCommentId).update({
          'repliesCount': FieldValue.increment(1),
        });
      }

      // 🔔 Notification Logic (Skip for AI products)
      if (!isAI) {
        final productSnap = await productDoc.get();
        final data = productSnap.data() as Map<String, dynamic>?;
        final productOwnerId = data?['createdBy'];

        if (productOwnerId != null && productOwnerId != currentUserId) {
          await NotificationService.createNotification(
            userId: productOwnerId,
            actorId: currentUserId,
            actorName:
                currentUser.displayName ?? currentUser.username ?? 'User',
            actorPhoto: currentUser.profilePicture ?? '',
            productId: productId,
            type: 'comment',
            message:
                "${currentUser.displayName ?? currentUser.username} commented on your product",
          );
        }
      }

      return ref.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /* ---------------- Streams ---------------- */

  static Stream<List<CommentModel>> getProductComments(
    String productId, {
    bool isAI = false,
  }) {
    // ✅ CRASH FIX: Empty ID check (Skeleton ke liye)
    if (productId.isEmpty) return Stream.value([]);

    return _getCollection(isAI)
        .doc(productId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (q) => q.docs
              .map((d) => CommentModel.fromFirestore(d))
              .where((c) => !c.isDeleted)
              .toList(),
        );
  }

  static Stream<List<CommentModel>> getCommentReplies(
    String productId,
    String parentCommentId, {
    bool isAI = false,
  }) {
    // ✅ CRASH FIX
    if (productId.isEmpty) return Stream.value([]);

    return _getCollection(isAI)
        .doc(productId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (q) => q.docs
              .map((d) => CommentModel.fromFirestore(d))
              .where((c) => !c.isDeleted)
              .toList(),
        );
  }

  /* ---------------- Update ---------------- */
  static Future<bool> updateComment(
    String productId,
    String commentId,
    String newContent, {
    bool isAI = false,
  }) async {
    try {
      await _getCollection(
        isAI,
      ).doc(productId).collection('comments').doc(commentId).update({
        'content': newContent.trim(),
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  /* ---------------- Soft Delete ---------------- */
  static Future<bool> deleteComment(
    String productId,
    String commentId, {
    bool isAI = false,
  }) async {
    try {
      final productRef = _getCollection(isAI).doc(productId);
      final commentRef = productRef.collection('comments').doc(commentId);

      final snap = await commentRef.get();
      if (!snap.exists) return false;

      final comment = CommentModel.fromFirestore(snap);

      // Soft delete main comment
      await commentRef.update({
        'isDeleted': true,
        'content': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Handle replies and counts
      if (comment.parentCommentId == null) {
        final repliesQ = await productRef
            .collection('comments')
            .where('parentCommentId', isEqualTo: commentId)
            .get();

        final total = 1 + repliesQ.docs.length;
        await productRef.update({'commentCount': FieldValue.increment(-total)});

        // Soft delete all replies
        for (final r in repliesQ.docs) {
          await r.reference.update({
            'isDeleted': true,
            'content': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // It's a reply
        await productRef.update({'commentCount': FieldValue.increment(-1)});
        await productRef
            .collection('comments')
            .doc(comment.parentCommentId!)
            .update({'repliesCount': FieldValue.increment(-1)});
      }

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /* ---------------- Upvote Comment ---------------- */
  static Future<bool> upvoteComment(
    String productId,
    String commentId, {
    bool isAI = false,
  }) async {
    try {
      final productRef = _getCollection(isAI).doc(productId);

      await productRef.collection('comments').doc(commentId).update({
        'upvotes': FieldValue.increment(1),
      });

      // 🔔 Notification logic (Only for Normal Products)
      if (!isAI) {
        final productSnap = await productRef.get();
        final data = productSnap.data() as Map<String, dynamic>?;
        final productOwnerId = data?['createdBy'];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        if (productOwnerId != null && currentUserId != null) {
          final currentUser = await UserService.getCurrentUserProfile();
          if (currentUser != null && productOwnerId != currentUserId) {
            await NotificationService.createNotification(
              userId: productOwnerId,
              actorId: currentUserId,
              actorName:
                  currentUser.displayName ?? currentUser.username ?? 'User',
              actorPhoto: currentUser.profilePicture ?? '',
              productId: productId,
              type: 'upvote',
              message:
                  "${currentUser.displayName ?? currentUser.username} upvoted a comment on your product",
            );
          }
        }
      }

      return true;
    } catch (e) {
      print('Error upvoting comment: $e');
      return false;
    }
  }

  /* ---------------- Count stream ---------------- */
  static Stream<int> getCommentCount(String productId, {bool isAI = false}) {
    // ✅ CRASH FIX: Return 0 if ID is empty (Skeleton)
    if (productId.isEmpty) return Stream.value(0);

    return _getCollection(isAI).doc(productId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = (doc.data() ?? {}) as Map<String, dynamic>;
      return (data['commentCount'] ?? 0) as int;
    });
  }
}