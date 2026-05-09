import 'package:flutter/material.dart';

// Empty common_widgets placeholder
class NexusCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const NexusCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: child,
  );
}
