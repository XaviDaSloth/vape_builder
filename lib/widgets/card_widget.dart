import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback? onTap;

  const CustomCard({super.key, required this.label, this.imagePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensures no unwanted background color
      child: InkWell(
        onTap: onTap ?? () => print('Card tapped: $label'),
        borderRadius: BorderRadius.circular(12), // Prevents ripple overflow
        splashColor: Theme.of(context).colorScheme.secondary.withAlpha(77), // Light bounce effect
        highlightColor: Theme.of(context).colorScheme.secondary.withAlpha(26), // Subtle highlight
        child: Ink(
          width: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary, // Use theme color
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image placeholder (or actual asset)
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Light grey placeholder
                    borderRadius: BorderRadius.circular(8),
                    image: imagePath != null
                        ? DecorationImage(image: AssetImage(imagePath!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imagePath == null
                      ? const Icon(Icons.image, size: 40, color: Colors.grey) // Placeholder icon
                      : null, // If image exists, don't show icon
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
