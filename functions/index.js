const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/* ========== 🔔 Notification on new comment (1st Gen) ========== */
exports.onNewComment = functions.firestore
    .document("products/{productId}/comments/{commentId}")
    .onCreate(async (snap, context) => {
        const comment = snap.data();
        const { productId } = context.params;

        if (!comment) return;

        const productDoc = await db.collection("products").doc(productId).get();
        if (!productDoc.exists) return;

        const product = productDoc.data();
        const ownerId = product?.createdBy;

        if (!ownerId || ownerId === comment.userId) return;

        await db.collection("notifications").add({
            userId: ownerId,
            type: "comment",
            productId,
            actorId: comment.userId,
            actorName: comment.userInfo?.displayName ?? "Someone",
            actorPhoto: comment.userInfo?.profilePicture ?? "",
            message: `${comment.userInfo?.displayName ?? "Someone"} commented on your product.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

/* ========== 🔔 Notification on upvote (1st Gen) ========== */
exports.onNewUpvote = functions.firestore
    .document("products/{productId}/upvotes/{userId}")
    .onCreate(async (snap, context) => {
        const upvote = snap.data();
        const { productId } = context.params;

        if (!upvote) return;

        const productDoc = await db.collection("products").doc(productId).get();
        if (!productDoc.exists) return;

        const product = productDoc.data();
        const ownerId = product?.createdBy;

        if (!ownerId || ownerId === upvote.userId) return;

        await db.collection("notifications").add({
            userId: ownerId,
            type: "upvote",
            productId,
            actorId: upvote.userId,
            actorName: upvote.userInfo?.displayName ?? "Someone",
            actorPhoto: upvote.userInfo?.profilePicture ?? "",
            message: `${upvote.userInfo?.displayName ?? "Someone"} upvoted your product.`,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

/* ========== 📈 Build Daily Trending (1st Gen) ========== */
async function buildTrending(target) {
    const start = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth(), target.getUTCDate()));
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + 1);

    const productsSnap = await db
        .collection("products")
        .where("status", "==", "published")
        .where("launchDate", ">=", start)
        .where("launchDate", "<", end)
        .orderBy("launchDate")
        .orderBy("upvoteCount", "desc")
        .limit(50)
        .get();

    const topProducts = productsSnap.docs.map((doc, i) => ({
        productId: doc.id,
        rank: i + 1,
        upvoteCount: doc.data().upvoteCount ?? 0,
        name: doc.data().name ?? "",
        tagline: doc.data().tagline ?? "",
        logoUrl: doc.data().logoUrl ?? "",
    }));

    const dateId = `${start.getUTCFullYear()}-${String(start.getUTCMonth() + 1).padStart(2, "0")}-${String(start.getUTCDate()).padStart(2, "0")}`;

    await db.collection("dailyRankings").doc(dateId).set({
        date: admin.firestore.Timestamp.fromDate(start),
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        topProducts,
        totalProducts: topProducts.length,
    });

    return dateId;
}

/* ========== 🕛 Schedule job (1st Gen) ========== */
exports.scheduledDailyTrending = functions.pubsub
    .schedule("every day 00:05")
    .timeZone("UTC")
    .onRun(async () => {
        const todayUTC = new Date();
        await buildTrending(todayUTC);
    });

/* ========== ⚡ Callable trigger (1st Gen) ========== */
exports.generateDailyTrendingNow = functions.https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
        throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const doc = await db.collection("users").doc(context.auth.uid).get();
    if (!doc.exists || doc.data().role !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Admins only");
    }

    const target = new Date();
    return await buildTrending(target);
});


exports.ai = require("./ai");
