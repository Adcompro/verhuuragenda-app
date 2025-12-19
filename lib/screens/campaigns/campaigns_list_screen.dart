import 'package:flutter/material.dart';

class CampaignsListScreen extends StatelessWidget {
  const CampaignsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campagnes'),
      ),
      body: const Center(
        child: Text('Campagnes (alleen lezen) - te implementeren'),
      ),
    );
  }
}
