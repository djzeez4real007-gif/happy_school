import 'package:flutter/material.dart';

class DashboardProgressCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const DashboardProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value.clamp(0, 100);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              borderRadius: BorderRadius.circular(20),
              color: color,
              backgroundColor: Colors.grey.shade300,
            ),

            const SizedBox(height: 15),

            Text(
              "${percentage.toStringAsFixed(1)} %",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
