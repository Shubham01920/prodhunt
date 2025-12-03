import 'package:flutter/material.dart';
import 'package:prodhunt/widgets/custom_description_box.dart';

class ProductDetailedPage extends StatelessWidget {
  const ProductDetailedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
            Text("Product" , style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
              const SizedBox(height: 20),

              // --- Product Image ---
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.speaker,
                    size: 100,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Title ---
              const Text(
                "EchoBrain Pro",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                "Your AI-Powered Intelligent Hub",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 25),

              // --- UPDATED STATS ROW ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Upvote Pill Container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "1.2K Upvotes",
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Members Section Container (User Suggestion Applied)
                  // Wrapping this in a Container ensures it groups tightly
                  Container(
                    padding: EdgeInsets.only(left: 25, top: 10, bottom: 5),
                    width: 180,
                    height: 60,

                    decoration: BoxDecoration(
                      color: Colors.white,

                    ),

                    child: Row(
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.group_outlined),
                               SizedBox(width: 5,),
                                Text("250+"),
                              ],
                            ),

                            Text("Community"),
                          ],
                        ),

                        SizedBox(width: 5),

                        Column(
                          children: [
                            Icon(Icons.person_outline),

                            Text("Members"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Engagement Row ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add, color: Colors.deepOrange),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "55",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Saved by users",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.message_outlined,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "120",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Comments",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- Bottom Details ---
              const CustomDescriptionBox(title: "Detailed Description"),
              const SizedBox(height: 10),
              const CustomDescriptionBox(title: "Key Features & Specs"),

              const SizedBox(height: 30),

              // --- Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Visit Official Website",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
