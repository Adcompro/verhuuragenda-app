import 'package:flutter/material.dart';

class MaintenanceListScreen extends StatelessWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onderhoud'),
      ),
      body: const Center(
        child: Text('Onderhoudstaken - te implementeren'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create maintenance task
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
