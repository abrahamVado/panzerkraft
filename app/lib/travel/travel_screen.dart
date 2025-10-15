import 'package:flutter/material.dart';

import 'auction_panel.dart';
import 'map_screen.dart';
import 'ride_creation_form.dart';

class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  static const routeName = '/travel';

  @override
  Widget build(BuildContext context) {
    //1.- Adapt layout so map and controls are comfortable on any screen width.
    return Scaffold(
      appBar: AppBar(title: const Text('Travel orchestration')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const MapScreen(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: const [
                      RideCreationForm(),
                      AuctionPanel(),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView(
            children: const [
              SizedBox(height: 320, child: MapScreen()),
              RideCreationForm(),
              AuctionPanel(),
            ],
          );
        },
      ),
    );
  }
}
