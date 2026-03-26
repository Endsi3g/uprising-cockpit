import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead.dart';
import '../../repositories/lead_repository.dart';
import '../../repositories/stats_repository.dart';
import '../../models/stats.dart';
import 'widgets/kpi_hero_card.dart';
import 'widgets/lead_card.dart';
import 'widgets/period_filter_tabs.dart';

// Providers
final _periodProvider = StateProvider<String>((ref) => '30d');

final _statsProvider = FutureProvider.family<PeriodStats, String>((ref, period) {
  final repo = StatsRepository(SupabaseConfig.client);
  return repo.fetchStats(businessId: kDevBusinessId, period: period);
});

final _leadsProvider = StreamProvider.family<List<Lead>, String>((ref, period) {
  final repo = LeadRepository(SupabaseConfig.client);
  return repo.watchLeads(businessId: kDevBusinessId, period: period);
});

class CockpitScreen extends ConsumerWidget {
  const CockpitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final stats = ref.watch(_statsProvider(period));
    final leads = ref.watch(_leadsProvider(period));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(_statsProvider);
            ref.invalidate(_leadsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cockpit',
                              style: Theme.of(context).textTheme.headlineLarge),
                          Text('Résultats IA en temps réel',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.smart_toy_outlined),
                            color: AppColors.primary,
                            onPressed: () => context.push('/ai'),
                            tooltip: 'Assistant IA',
                          ),
                          IconButton(
                            icon: const Icon(Icons.receipt_long_outlined),
                            color: AppColors.textSecondary,
                            onPressed: () => context.push('/invoices'),
                            tooltip: 'Factures & Devis',
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            color: AppColors.textSecondary,
                            onPressed: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // KPI Hero
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: stats.when(
                    data: (s) => KpiHeroCard(stats: s, period: period),
                    loading: () => _shimmerHero(),
                    error: (e, _) => _errorCard(e.toString()),
                  ),
                ),
              ),

              // Period filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: PeriodFilterTabs(
                    selected: period,
                    onChanged: (p) =>
                        ref.read(_periodProvider.notifier).state = p,
                  ),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text('Urgences captées',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      leads.when(
                        data: (l) => Text('${l.length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.primary)),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // Lead feed
              leads.when(
                data: (list) {
                  if (list.isEmpty) {
                    return SliverToBoxAdapter(child: _emptyState());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: LeadCard(
                          lead: list[i],
                          onTap: () => context.push('/leads/${list[i].id}'),
                        ),
                      ),
                      childCount: list.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _shimmerCard(),
                    ),
                    childCount: 4,
                  ),
                ),
                error: (e, _) =>
                    SliverToBoxAdapter(child: _errorCard(e.toString())),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerHero() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('Aucune urgence pour cette période',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _errorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
