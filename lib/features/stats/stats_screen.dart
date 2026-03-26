import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('Statistiques', style: Theme.of(context).textTheme.headlineLarge),
                       const SizedBox(height: 4),
                       Text('Analyse des performances IA et revenus', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: PeriodFilterTabs(
                    selected: period,
                    onChanged: (p) => ref.read(_statsPeriodProvider.notifier).state = p,
                  ),
                ).animate(delay: 200.ms).fadeIn(),
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
                        _DynamicInsights(stats: stats).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            _KpiTile(
                              label: 'Sauvés',
                              value: stats.formattedSavedFull,
                              icon: Icons.savings_outlined,
                              color: AppColors.success,
                            ).animate(delay: 400.ms).fadeIn().scale(),
                            const SizedBox(width: 12),
                            _KpiTile(
                              label: 'Interceptés',
                              value: '${stats.totalLeadsIntercepted}',
                              icon: Icons.phone_in_talk_outlined,
                              color: AppColors.primary,
                            ).animate(delay: 500.ms).fadeIn().scale(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _KpiTile(
                              label: 'Perdus',
                              value: '${stats.totalLeadsLost}',
                              icon: Icons.call_missed_outlined,
                              color: AppColors.error,
                            ).animate(delay: 600.ms).fadeIn().scale(),
                            const SizedBox(width: 12),
                            _KpiTile(
                              label: 'Conversion',
                              value: '${stats.conversionRate.toStringAsFixed(0)}%',
                              icon: Icons.trending_up,
                              color: AppColors.warning,
                            ).animate(delay: 700.ms).fadeIn().scale(),
                          ],
                        ),
                        const SizedBox(height: 32),

                        _ChartCard(
                          title: 'Urgences captées vs perdues',
                          child: _UrgencesBarChart(daily: stats.daily).animate(delay: 800.ms).fadeIn(),
                        ),
                        const SizedBox(height: 16),

                        _ChartCard(
                          title: 'Revenus sauvés (\$ CAD)',
                          child: _SavingsLineChart(daily: stats.daily).animate(delay: 900.ms).fadeIn(),
                        ),
                        const SizedBox(height: 40),
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
  const _KpiTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1)),
            ),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          AspectRatio(aspectRatio: 1.5, child: child),
        ],
      ),
    );
  }
}

class _DynamicInsights extends StatelessWidget {
  final PeriodStats stats;
  const _DynamicInsights({required this.stats});

  @override
  Widget build(BuildContext context) {
    String insight;
    Color color;
    IconData icon;

    if (stats.conversionRate >= 70) {
      insight = 'Performance remarquable. Vous convertissez ${stats.conversionRate.toStringAsFixed(0)}% des leads.';
      color = AppColors.secondary;
      icon = Icons.auto_awesome;
    } else if (stats.conversionRate >= 40) {
      insight = 'Interception de ${stats.totalLeadsIntercepted} leads. Améliorez le rappel pour booster la conversion.';
      color = AppColors.primary;
      icon = Icons.bolt;
    } else {
      insight = '${stats.totalLeadsLost} leads perdus. Vérifiez vos réglages de transfert Bland AI.';
      color = AppColors.error;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights Directs', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(insight, style: TextStyle(fontSize: 14, color: color.withOpacity(0.9), height: 1.3, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
    if (daily.isEmpty) return const Center(child: Text('Aucune donnée'));
    
    final bars = daily.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.leadsIntercepted.toDouble(),
            color: AppColors.primary,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: e.value.leadsLost.toDouble(),
            color: AppColors.error.withOpacity(0.4),
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)))),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    if (daily.isEmpty) return const Center(child: Text('Aucune donnée'));
    final spots = daily.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.savedCad)).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.secondary.withOpacity(0.1)),
            dotData: const FlDotData(show: false),
          ),
        ],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)))),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
