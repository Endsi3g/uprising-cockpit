import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stats.dart';
import '../../repositories/stats_repository.dart';
import '../cockpit/widgets/period_filter_tabs.dart';

final _statsPeriodProvider = StateProvider<String>((ref) => '30d');
final _statsScreenProvider =
    FutureProvider.family<PeriodStats, String>((ref, period) {
  final repo = StatsRepository(SupabaseConfig.client);
  return repo.fetchStats(businessId: kDevBusinessId, period: period);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_statsPeriodProvider);
    final statsAsync = ref.watch(_statsScreenProvider(period));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(_statsScreenProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text('Statistiques',
                      style: Theme.of(context).textTheme.headlineLarge),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: PeriodFilterTabs(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(_statsPeriodProvider.notifier).state = p,
                  ),
                ),
              ),
              statsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
                data: (stats) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // KPI tiles row
                        Row(
                          children: [
                            _KpiTile(
                              label: 'Sauvés',
                              value: stats.formattedSavedFull,
                              icon: Icons.savings_outlined,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            _KpiTile(
                              label: 'Interceptés',
                              value: '${stats.totalLeadsIntercepted}',
                              icon: Icons.phone_in_talk_outlined,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _KpiTile(
                              label: 'Perdus',
                              value: '${stats.totalLeadsLost}',
                              icon: Icons.call_missed_outlined,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 12),
                            _KpiTile(
                              label: 'Conversion',
                              value:
                                  '${stats.conversionRate.toStringAsFixed(0)}%',
                              icon: Icons.trending_up,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Bar chart
                        _ChartCard(
                          title: 'Urgences captées vs perdues',
                          child: _UrgencesBarChart(daily: stats.daily),
                        ),
                        const SizedBox(height: 16),

                        // Savings line chart
                        _ChartCard(
                          title: 'Revenus sauvés (\$ CAD)',
                          child: _SavingsLineChart(daily: stats.daily),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

class _UrgencesBarChart extends StatelessWidget {
  final List<DailyStats> daily;
  const _UrgencesBarChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(
          child: Text('Aucune donnée', style: TextStyle(color: AppColors.textSecondary)));
    }
    final bars = daily.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.leadsIntercepted.toDouble(),
            color: AppColors.primary,
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: e.value.leadsLost.toDouble(),
            color: AppColors.danger.withOpacity(0.6),
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.borderLight, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}

class _SavingsLineChart extends StatelessWidget {
  final List<DailyStats> daily;
  const _SavingsLineChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(
          child: Text('Aucune donnée', style: TextStyle(color: AppColors.textSecondary)));
    }
    final spots = daily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.savedCad);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withOpacity(0.08),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.borderLight, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                '${(v / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
