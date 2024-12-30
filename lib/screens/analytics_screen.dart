import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Можно расширить функционал аналитики при необходимости
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: const Center(
        child: Text(
          'Здесь будет аналитика: общее количество товаров, приход и расход.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}