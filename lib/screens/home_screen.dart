import 'package:flutter/material.dart';
import '../widgets/contraction_button.dart';
import '../widgets/contraction_list.dart';
import '../widgets/stats_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrações'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Center(child: ContractionButton()),
            const SizedBox(height: 32),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Histórico',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const ContractionList(),
            const Divider(),
            const StatsSection(),
          ],
        ),
      ),
    );
  }
}
