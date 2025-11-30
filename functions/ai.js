const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Firebase Config se Gemini Key
const GEMINI_KEY = functions.config().gemini?.key;

// --------------------------
// Gemini Call (Only JSON)
// --------------------------
async function callGemini() {
    if (!GEMINI_KEY) {
        console.error("❌ Gemini key missing!");
        return [];
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${GEMINI_KEY}`;

    console.log("⚡ Calling Gemini:", url);

    const body = {
        contents: [
            {
                parts: [
                    {
                        text: `
Return ONLY valid JSON.
Generate 5 realistic NEW tech products launched today.

Format:
[
  {
    "name": "",
    "tagline": "",
    "description": "",
    "website": ""
  }
]

NO MARKDOWN, NO EXTRA TEXT.
`
                    }
                ]
            }
        ]
    };

    try {
        const res = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
        });

        const json = await res.json();
        if (json.error) {
            console.error("❌ Gemini Error:", json);
            return [];
        }

        const raw =
            json?.candidates?.[0]?.content?.parts?.[0]?.text ||
            json?.candidates?.[0]?.content?.[0]?.text;

        if (!raw) return [];

        const arrayText = raw.match(/\[.*\]/s)?.[0];
        if (!arrayText) return [];

        return JSON.parse(arrayText);

    } catch (err) {
        console.error("❌ FETCH FAILED:", err);
        return [];
    }
}

// -----------------------------------
// SAVE AI PRODUCTS + AUTO IMAGE GENERATION
// -----------------------------------
exports.fetchAiProducts = functions.pubsub
    .schedule("every 6 hours")
    .timeZone("UTC")
    .onRun(async () => {
        console.log("▶ Running AI fetch…");

        const items = await callGemini();
        if (!items || items.length === 0) {
            console.log("⚠ No items returned");
            return;
        }

        const { FieldValue } = require("firebase-admin/firestore");
        let added = 0;

        for (const p of items) {
            if (!p.name) continue;

            // Duplicate prevention
            const q = await db
                .collection("aiProducts")
                .where("name", "==", p.name.trim())
                .limit(1)
                .get();

            if (!q.empty) continue;

            // ---------------------------
            // Generate AI Image (HD)
            // ---------------------------
            const prompt = `${p.name} ${p.tagline} futuristic tech product render, high quality, ultra realistic`;
            const encoded = encodeURIComponent(prompt);

            const aiImageUrl =
                `https://image.pollinations.ai/prompt/${encoded}?width=800&height=600&model=flux&nologo=true`;

            // ---------------------------
            // Save Product
            // ---------------------------
            await db.collection("aiProducts").add({
                name: p.name,
                tagline: p.tagline || "",
                description: p.description || "",
                website: p.website || "",
                image: aiImageUrl,        // FINAL GENERATED IMAGE
                createdAt: FieldValue.serverTimestamp(),
                source: "gemini",
            });

            added++;
        }

        console.log(`✅ AI Products Added: ${added}`);
        return { added };
    });
