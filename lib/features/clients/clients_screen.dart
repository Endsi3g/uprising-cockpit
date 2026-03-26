import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _filteredClientsProvider = FutureProvider<List<Client>>((ref) async {
  final query = ref.watch(_searchQueryProvider).toLowerCase();
  final data = await SupabaseConfig.client
      .from(kTableClients)
      .select()
      .eq('business_id', kDevBusinessId)
      .order('name');
  
  final clients = (data as List).map((e) => Client.fromJson(e)).toList();
  
  if (query.isEmpty) return clients;
  return clients.where((c) => 
    c.name.toLowerCase().contains(query) || 
    (c.phone?.contains(query) ?? false) ||
    (c.city?.toLowerCase().contains(query) ?? false)
  ).toList();
});

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_filteredClientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clients', style: Theme.of(context).textTheme.headlineLarge),
                   const SizedBox(height: 4),
                   Text('Répertoire complet de vos contacts', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ).animate().fadeIn().slideX(begin: -0.1),
            ),
            
            // Search Bar with Glass/Premium Look
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un nom, téléphone, ville...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),
            
            const SizedBox(height: 16),

            Expanded(
              child: clientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (clients) {
                  if (clients.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: clients.length,
                    itemBuilder: (ctx, i) => _ClientCard(client: clients[i]).animate(delay: (300 + i * 50).ms).fadeIn().slideY(begin: 0.1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ).animate(delay: 600.ms).scale(curve: Curves.elasticOut),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('Aucun client trouvé', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final initials = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/clients/${client.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(client.city ?? 'Ville inconnue', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _AiInterventionBadge(),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.borderLight),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _ClientActionButton(
                          icon: Icons.phone_forwarded_outlined,
                          label: 'Appeler',
                          onTap: () async {
                             if (client.phone != null) {
                               final url = Uri.parse('tel:${client.phone}');
                               if (await canLaunchUrl(url)) await launchUrl(url);
                             }
                          },
                        ),
                        const SizedBox(width: 12),
                        _ClientActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          onTap: () async {
                             if (client.phone != null) {
                               final url = Uri.parse('https://wa.me/${client.phone}');
                               if (await canLaunchUrl(url)) await launchUrl(url);
                             }
                          },
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
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

class _ClientActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ClientActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AiInterventionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: AppColors.secondary, size: 12),
          SizedBox(width: 4),
          Text('AI WIN', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 2.s, color: Colors.white);
  }
}
