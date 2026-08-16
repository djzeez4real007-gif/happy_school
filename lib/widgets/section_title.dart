import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (actionText != null)
          InkWell(
            onTap: onTap,
            child: Text(
              actionText!,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
