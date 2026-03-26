import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead.dart';
import '../../models/stats.dart';
import '../../repositories/lead_repository.dart';
import '../../repositories/stats_repository.dart';

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
    final statsAsync = ref.watch(_statsProvider(period));
    final leadsAsync = ref.watch(_leadsProvider(period));

    ref.listen(_statsProvider(period), (prev, next) {
      next.whenData((s) async {
        await HomeWidget.saveWidgetData<String>(
            'savings', '\$${s.totalSavedCad.toStringAsFixed(0)}');
        await HomeWidget.updateWidget(
          name: 'HomeWidgetProvider',
          iOSName: 'UprisingCockpitWidget',
        );
      });
    });

    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map Background (Top half placeholder representing Google Maps)
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Image.network(
              'https://images.unsplash.com/photo-1569336415962-a4bd9f6dfc0f?auto=format&fit=crop&q=80&w=800&h=600', // Cleaner, lighter map
              fit: BoxFit.cover,
              color: AppColors.background.withOpacity(0.4), 
              colorBlendMode: BlendMode.lighten,
            ),
          ),
          
          // Gradient fade for top header readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.95),
                    AppColors.background.withOpacity(0.6),
                    AppColors.background.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Scrollable Layer
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header (Date + Icons)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, size: 28),
                              color: AppColors.textPrimary,
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.auto_awesome, size: 26),
                              color: AppColors.textPrimary,
                              onPressed: () => context.push('/ai'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Bonjour, Alex',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ),

                // Large spacing exposing the background Map
                const SliverToBoxAdapter(child: SizedBox(height: 160)),

                // Overlap text over map (Visits worth) & Right pill button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leadsAsync.when(
                              data: (leads) => Text(
                                '${leads.length} urgence${leads.length > 1 ? 's' : ''} en attente',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              loading: () => const Text('Chargement...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              error: (_, __) => const Text('Erreur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '0 terminées aujourd\'hui',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // View all Pill Action
                        GestureDetector(
                          onTap: () => context.push('/jobs'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Tout voir',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 18, color: AppColors.textPrimary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Horizontal Visit Cards (Jobber layout)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 145,
                    child: leadsAsync.when(
                      data: (leads) {
                        if (leads.isEmpty) {
                          return _buildEmptyVisitCard();
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            return _JobberVisitCard(lead: leads[index]);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erreur: $e')),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // "This week" and stats preview
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cette semaine',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Aperçu des performances',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => context.push('/stats'),
                              child: const Text(
                                'Voir stats >',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        statsAsync.when(
                          data: (s) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.savings_outlined, color: AppColors.success, size: 28),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Économies réalisées', style: TextStyle(color: AppColors.textSecondary)),
                                    Text(s.formattedTotalSaved, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Floating Action Button (+) 
          Positioned(
            right: 20,
            bottom: 20, // Tab bar avoidance padding handled implicitly or needs padding
            child: SafeArea(
              child: FloatingActionButton(
                backgroundColor: AppColors.textPrimary, // Jobber uses dark rounded button
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {},
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVisitCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text('Aucune urgence', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _JobberVisitCard extends StatelessWidget {
  final Lead lead;

  const _JobberVisitCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final clientName = lead.client?.name ?? 'Client Inconnu';
    final initials = clientName.length > 1 ? clientName.substring(0, 2).toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push('/leads/${lead.id}'),
      child: Container(
        width: 310, // Width constraint for horizontal list
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Jobber-style Green Vertical Line
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('HH:mm').format(lead.triggeredAt),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.clientAddress ?? 'Aucune adresse enregistrée',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            lead.displayTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
