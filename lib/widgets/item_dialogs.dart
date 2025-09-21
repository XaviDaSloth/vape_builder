import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

void showItemDetails(
  BuildContext context,
  String itemKey,
  String itemName,
  String description,
  String imagePath,
  int stocksLeft,
  double price,
) async {
  var box = Hive.box('inventoryBox');
  var itemData = box.get(itemKey) ?? {};
  List<int> ratings = List<int>.from(itemData['ratings'] ?? []);
  double averageRating = ratings.isNotEmpty
      ? ratings.reduce((a, b) => a + b) / ratings.length
      : 0.0; // Compute average rating

  int? selectedRating;
  bool showSubmit = false;

  Widget displayImage(String path) {
    if (path.startsWith('/')) {
      return Image.file(
        File(path),
        width: 120,
        height: 250,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        path,
        width: 120,
        height: 250,
        fit: BoxFit.cover,
      );
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: displayImage(imagePath),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(description, style: const TextStyle(fontSize: 14), overflow: TextOverflow.visible),
                              const SizedBox(height: 10),
                              Text("Price: ₱$price", style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 10),
                              Text(
                                "Stocks Left: $stocksLeft",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 163, 163, 163),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ⭐ Display Average Rating
                              Row(
                                children: [
                                  Text(
                                    "Rating: ${averageRating.toStringAsFixed(1)} ",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.star, color: Colors.amber, size: 20),
                                ],
                              ),
                              Text(" (${ratings.length} reviews)", style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rating Stars Selection with Splash Effect
                    Text("Rate this product:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Material(
                          color: Colors.transparent, // Ensures splash effect blends naturally
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedRating = index + 1;
                                showSubmit = selectedRating != null;
                              });
                            },
                            splashColor: Colors.amber.withAlpha(77), // 30% opacity splash
                            highlightColor: Colors.amber.withAlpha(26), // 10% opacity highlight
                            borderRadius: BorderRadius.circular(12), // Smooth edges
                            child: Padding(
                              padding: const EdgeInsets.all(8.0), // Adjust padding for effect
                              child: Icon(
                                index < (selectedRating ?? 0) ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Submit Button with Splash Effect
                    if (showSubmit)
                      Material(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                          ),
                          onPressed: () {
                            if (selectedRating != null) {
                              addRatingToHive(itemKey, selectedRating!);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Submit Rating", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Close Button with Splash Effect
                    Material(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Close", style: TextStyle(color: Colors.white)),

                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// 🔹 Function to Save Rating to Hive
void addRatingToHive(String itemKey, int rating) async {
  var box = await Hive.openBox('inventoryBox'); // Ensure box is open
  var itemData = box.get(itemKey) ?? {};
  
  List<int> ratings = List<int>.from(itemData['ratings'] ?? []);
  ratings.add(rating);

  box.put(itemKey, {...itemData, 'ratings': ratings});
}

