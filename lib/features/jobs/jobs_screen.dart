import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Jobs', style: Theme.of(context).textTheme.headlineLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text('Tous les leads & interventions',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 16),

            // Period filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PeriodFilterTabs(
                selected: period,
                onChanged: (p) =>
                    ref.read(_jobsPeriodProvider.notifier).state = p,
              ),
            ),
            const SizedBox(height: 12),

            // Status filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: status == null,
                    onTap: () =>
                        ref.read(_jobsStatusProvider.notifier).state = null,
                  ),
                  ...LeadStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: s.label,
                          selected: status == s,
                          onTap: () =>
                              ref.read(_jobsStatusProvider.notifier).state = s,
                        ),
                      )),
                ],
              ),
            ),
            // Map card
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _MapRedirectCard(),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: jobsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_off_outlined,
                              size: 48, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text('Aucun job pour cette période',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => LeadCard(
                      lead: jobs[i],
                      onTap: () => context.push('/leads/${jobs[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MapRedirectCard extends StatelessWidget {
  const _MapRedirectCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://www.google.com/maps');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=600&h=200'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, color: Colors.white, size: 28),
              SizedBox(height: 8),
              Text(
                'Voir la carte des interventions',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
