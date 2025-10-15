import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child, this.width = 280});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    //1.- Provide a reusable layout with padding and rounded corners for cards.
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
