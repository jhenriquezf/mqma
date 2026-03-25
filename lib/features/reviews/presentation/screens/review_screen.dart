import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final String eventId;
  const ReviewScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ReviewScreen')),
    body: const Center(child: Text('En construcción')),
  );
}
