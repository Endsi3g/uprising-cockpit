import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          // 1. Real Interactive Map (FlutterMap) - Fullscreen background or half?
          // User wanted interactive. Let's make it more immersive.
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(45.5017, -73.5673),
                initialZoom: 13,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all, // Fully interactive
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.uprising.cockpit',
                  tileDisplay: const TileDisplay.fadeIn(),
                ),
                leadsAsync.when(
                  data: (leads) => MarkerLayer(
                    markers: leads.asMap().entries.map((e) {
                      final i = e.key;
                      return Marker(
                        point: LatLng(45.5017 + (i * 0.008), -73.5673 + (i * 0.005)),
                        width: 50,
                        height: 50,
                        child: const _AnimatedMarker(),
                      );
                    }).toList(),
                  ),
                  loading: () => const MarkerLayer(markers: []),
                  error: (_, __) => const MarkerLayer(markers: []),
                ),
              ],
            ),
          ),
          
          // Liquid Glass Header overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: GlassCard(
                borderRadius: BorderRadius.zero,
                opacity: 0.15,
                blur: 15,
                padding: const EdgeInsets.only(bottom: 20),
                border: const Border(bottom: BorderSide(color: Colors.white24, width: 1)),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormatted, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                _HeaderIconButton(icon: Icons.notifications_outlined, onTap: () {}),
                                const SizedBox(width: 12),
                                _HeaderIconButton(icon: Icons.auto_awesome_outlined, isAccent: true, onTap: () => context.push('/ai')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Bonjour, Alex', style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          // 2. Scrollable Action Sheet Content
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Live Status / Urgences Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             leadsAsync.when(
                               data: (leads) => Text(
                                 '${leads.length} urgence${leads.length > 1 ? 's' : ''} en attente',
                                 style: Theme.of(context).textTheme.headlineMedium,
                               ),
                               loading: () => const Text('Calcul...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                               error: (_, __) => const Text('Erreur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                             ),
                             const SizedBox(height: 4),
                             const Row(
                               children: [
                                 _PulseDot(),
                                 SizedBox(width: 8),
                                 Text('Mode Intervention Active', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                               ],
                             ),
                          ],
                        ),
                        _SecondaryPill(label: 'Tout voir', onTap: () => context.push('/jobs')),
                      ],
                    ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                    const SizedBox(height: 24),

                    // Horizontal List of Leads (Jobber Bento Style)
                    SizedBox(
                      height: 155,
                      child: leadsAsync.when(
                        data: (leads) {
                          if (leads.isEmpty) return _buildEmptyState();
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: leads.length,
                            itemBuilder: (ctx, i) => _BentoVisitCard(lead: leads[i]).animate(delay: (300 + i * 100).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur data: $e')),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Performance Insights (AI)
                    Text('Performances', style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 500.ms).fadeIn(),
                    const SizedBox(height: 16),
                    
                    statsAsync.when(
                      data: (s) => _PremiumStatsCard(stats: s).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 120), // Bottom padding
                  ],
                ),
              );
            },
          ),
          
          // 3. Floating Action Button (+) 
          Positioned(
            right: 24,
            bottom: 30,
            child: FloatingActionButton.large(
              onPressed: () {},
              backgroundColor: AppColors.textPrimary,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            ).animate(delay: 800.ms).scale(curve: Curves.elasticOut),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: Text('Aucune urgence', style: TextStyle(color: AppColors.textSecondary))),
    );
  }
}

class _AnimatedMarker extends StatelessWidget {
  const _AnimatedMarker();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(3, 3), duration: 2.s).fadeOut(),
        const Icon(Icons.location_on, color: AppColors.primary, size: 40),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
    ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 1.s, curve: Curves.easeInOut);
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;
  const _HeaderIconButton({required this.icon, required this.onTap, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isAccent ? AppColors.primary.withOpacity(0.1) : Colors.white24,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAccent ? AppColors.primary.withOpacity(0.2) : Colors.white38),
        ),
        child: Icon(icon, color: isAccent ? AppColors.primary : AppColors.textPrimary, size: 24),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(delay: 5.s, duration: 2.s, color: Colors.white24);
  }
}

class _SecondaryPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class _BentoVisitCard extends StatelessWidget {
  final Lead lead;
  const _BentoVisitCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final clientName = lead.client?.name ?? 'Client Inconnu';
    final initials = clientName.isNotEmpty ? clientName[0].toUpperCase() : '?';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/leads/${lead.id}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                      child: const Text('URGENCE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    Text(DateFormat('HH:mm').format(lead.triggeredAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(lead.clientAddress ?? 'Pas d\'adresse', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    const Text('Intervention immédiate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumStatsCard extends StatelessWidget {
  final PeriodStats stats;
  const _PremiumStatsCard({required this.stats});

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
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valeur Interceptée', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text('IA en service 24/7', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              Text(stats.formattedTotalSaved, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Taux Convers.', value: '${stats.conversionRate.toStringAsFixed(1)}%'),
              _StatItem(label: 'Urgences', value: stats.totalLeadsIntercepted.toString()),
              _StatItem(label: 'Temps rép.', value: '1.2s'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
