import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead.dart';
import '../../repositories/lead_repository.dart';
import '../cockpit/widgets/lead_card.dart';
import '../cockpit/widgets/period_filter_tabs.dart';

final _jobsPeriodProvider = StateProvider<String>((ref) => '30d');
final _jobsStatusProvider = StateProvider<LeadStatus?>((ref) => null);

final _jobsProvider =
    FutureProvider.family<List<Lead>, (String, LeadStatus?)>((ref, args) {
  final repo = LeadRepository(SupabaseConfig.client);
  return repo.fetchLeads(
    businessId: kDevBusinessId,
    period: args.$1,
    statusFilter: args.$2,
  );
});

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_jobsPeriodProvider);
    final status = ref.watch(_jobsStatusProvider);
    final jobsAsync = ref.watch(_jobsProvider((period, status)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Jobs', style: Theme.of(context).textTheme.headlineLarge),
                   const SizedBox(height: 4),
                   Text('Gestion des interventions et leads',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            
            const SizedBox(height: 24),

            // Period & Status Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  PeriodFilterTabs(
                    selected: period,
                    onChanged: (p) => ref.read(_jobsPeriodProvider.notifier).state = p,
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: 'Tous',
                    selected: status == null,
                    onTap: () => ref.read(_jobsStatusProvider.notifier).state = null,
                  ),
                  ...LeadStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: s.label,
                          selected: status == s,
                          onTap: () => ref.read(_jobsStatusProvider.notifier).state = s,
                        ),
                      )),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 20),

            // Interactive Map Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: jobsAsync.when(
                data: (jobs) => _PremiumMapCard(leads: jobs),
                loading: () => const _MapSkeleton(),
                error: (_, __) => const _MapSkeleton(),
              ),
            ).animate(delay: 400.ms).fadeIn().scale(),

            const SizedBox(height: 24),

            // List of Jobs
            Expanded(
              child: jobsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (jobs) {
                  if (jobs.isEmpty) return _buildEmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => LeadCard(
                      lead: jobs[i],
                      onTap: () => context.push('/leads/${jobs[i].id}'),
                    ).animate(delay: (500 + i * 50).ms).fadeIn().slideY(begin: 0.1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work_off_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('Aucun job trouvé', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('Créer un job manuellement')),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PremiumMapCard extends StatelessWidget {
  final List<Lead> leads;
  const _PremiumMapCard({required this.leads});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: leads.isNotEmpty 
                  ? LatLng(45.5017, -73.5673) // Default to Montreal center for overview
                  : const LatLng(45.5017, -73.5673),
                initialZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.uprising.cockpit',
                ),
                MarkerLayer(
                  markers: leads.asMap().entries.map((e) {
                     return Marker(
                       point: LatLng(45.5017 + (e.key * 0.01), -73.5673 + (e.key * 0.01)),
                       width: 30, height: 30,
                       child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                     );
                  }).toList(),
                ),
              ],
            ),
            Positioned(
              bottom: 12, right: 12,
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse('https://www.google.com/maps');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Itinéraire', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}
