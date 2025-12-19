import 'package:flutter/material.dart';

class BookingDetailScreen extends StatelessWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boeking #$bookingId'),
      ),
      body: const Center(
        child: Text('Boeking detail - te implementeren'),
      ),
    );
  }
}
