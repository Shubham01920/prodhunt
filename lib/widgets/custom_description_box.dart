import 'package:flutter/material.dart';

class CustomDescriptionBox extends StatelessWidget {
  const CustomDescriptionBox({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Match image background
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600, // Semi-bold
              color: Colors.black87,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
        ],
      ),
    );
  }
}