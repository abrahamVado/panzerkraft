import 'package:flutter/material.dart';

class TravelCtaButton extends StatelessWidget {
  const TravelCtaButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    //1.- Offer a friendly action that leads operators into the travel flow.
    return SizedBox(
      width: 280,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.directions_car),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Plan a new travel'),
        ),
      ),
    );
  }
}
