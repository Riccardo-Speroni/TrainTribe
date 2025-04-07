import 'package:flutter/material.dart';

class TrainCard extends StatelessWidget {
  final String title;
  final String details;
  final String additionalDetails;
  final String image;
  final List<String> list;
  final bool isExpanded;
  final VoidCallback onTap;

  const TrainCard({
    super.key,
    required this.title,
    required this.details,
    required this.additionalDetails,
    required this.image,
    required this.list,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // Allow the column to shrink-wrap its content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  details,
                  style: const TextStyle(fontSize: 14.0),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10.0),
                Image.asset(image, fit: BoxFit.cover, height: 200.0),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    additionalDetails,
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: list.map((item) => Text('- $item')).toList(),
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}