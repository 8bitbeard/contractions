import 'package:flutter/material.dart';
import '../widgets/contraction_button.dart';
import '../widgets/contraction_list.dart';
import '../widgets/stats_section.dart';
import '../widgets/summary_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contrações'),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Center(child: ContractionButton()),
            const SizedBox(height: 20),
            const SummaryBar(),
            const SizedBox(height: 8),
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.list_alt_outlined), text: 'Histórico'),
                Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Estatísticas'),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              dividerColor: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        ContractionList(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        StatsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
