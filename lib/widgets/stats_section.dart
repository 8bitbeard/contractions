import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/day_stats.dart';
import '../providers/contraction_provider.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static String formatDuration(Duration d) {
    final totalMinutes = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (totalMinutes == 0) return '${s}s';
    if (s == 0) return '${totalMinutes}min';
    return '${totalMinutes}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContractionProvider>();
    final grouped = provider.groupedByDay;
    final key = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayContractions = grouped[key] ?? [];
    final stats = DayStats(dayContractions);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              final k = DateTime(day.year, day.month, day.day);
              final events = grouped[k] ?? [];
              return events.isEmpty ? [] : [events.first];
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(70),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (dayContractions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text(
                'Nenhuma contração em ${DateFormat('d/MM/yyyy').format(_selectedDay)}',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          _StatsGrid(stats: stats),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.bar_chart, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Distribuição por período',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: _ContractionChart(stats: stats, theme: theme),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DayStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final fmt = _StatsSectionState.formatDuration;

    final items = [
      (Icons.favorite_rounded, 'Contrações', '${s.count}', false),
      (Icons.timer_outlined, 'Duração média', s.averageDuration != null ? fmt(s.averageDuration!) : '—', false),
      (Icons.swap_horiz_rounded, 'Intervalo médio', s.averageInterval != null ? fmt(s.averageInterval!) : '—', false),
      (Icons.hourglass_bottom_rounded, 'Tempo total', s.totalDuration != null ? fmt(s.totalDuration!) : '—', false),
      (Icons.arrow_upward_rounded, 'Maior contração', s.longestDuration != null ? fmt(s.longestDuration!) : '—', false),
      (Icons.arrow_downward_rounded, 'Menor contração', s.shortestDuration != null ? fmt(s.shortestDuration!) : '—', false),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: items
            .map((e) => _StatCard(icon: e.$1, label: e.$2, value: e.$3))
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
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

class _ContractionChart extends StatefulWidget {
  final DayStats stats;
  final ThemeData theme;

  const _ContractionChart({required this.stats, required this.theme});

  @override
  State<_ContractionChart> createState() => _ContractionChartState();
}

class _ContractionChartState extends State<_ContractionChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final slots = widget.stats.contractionsBySlot;
    final maxY = slots.fold(0, (m, v) => v > m ? v : m).toDouble();

    final groups = List.generate(12, (i) {
      final isTouched = _touchedIndex == i;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: slots[i].toDouble(),
            color: slots[i] == 0
                ? widget.theme.colorScheme.outlineVariant
                : isTouched
                    ? widget.theme.colorScheme.error
                    : widget.theme.colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY < 1 ? 2 : maxY + 1,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            setState(() {
              _touchedIndex = (event is FlTapUpEvent || event is FlPanEndEvent)
                  ? null
                  : response?.spot?.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, _, rod, _) {
              final start = (group.x * 2).toString().padLeft(2, '0');
              final end = ((group.x * 2) + 2).toString().padLeft(2, '0');
              final count = rod.toY.toInt();
              return BarTooltipItem(
                '${start}h – ${end}h\n',
                const TextStyle(color: Colors.white, fontSize: 11),
                children: [
                  TextSpan(
                    text: count == 0
                        ? 'nenhuma'
                        : '$count contração${count == 1 ? '' : 'ões'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                if (value != value.roundToDouble()) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final hour = (value.toInt() * 2).toString().padLeft(2, '0');
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${hour}h',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
