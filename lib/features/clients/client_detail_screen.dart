import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client.dart';

final clientDetailProvider = FutureProvider.family<Client?, String>((ref, id) async {
  final data = await SupabaseConfig.client
      .from(kTableClients)
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return Client.fromJson(data);
});

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fiche client', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Client introuvable'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  client.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Info
              _SectionCard(
                title: 'Coordonnées',
                children: [
                  _InfoRow(icon: Icons.phone_outlined, text: client.phone ?? 'Non spécifié'),
                  _InfoRow(icon: Icons.location_on_outlined, text: client.address ?? 'Non spécifié'),
                  _InfoRow(icon: Icons.location_city_outlined, text: client.city ?? 'Non spécifié'),
                ],
              ),
              const SizedBox(height: 16),

              // AI Analysis
              _SectionCard(
                title: 'Analyse IA',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _AiTag('Client VIP', AppColors.success),
                      _AiTag('Réactif', AppColors.primary),
                      _AiTag('Aime les détails', AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Résumé du profil : Ce client préfère être contacté par téléphone et pose beaucoup de questions techniques. Assurez-vous d\'avoir les détails du devis prêts avant d\'appeler.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Action suggérée : Rapport de suivi à envoyer d\'ici 48h.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bland AI Integration
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.record_voice_over_outlined, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Assistant Vocal (Bland AI)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lancer un appel automatisé avec l\'IA pour qualifier le besoin ou confirmer un rendez-vous.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          // Simuler l'appel Bland AI
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel Bland AI simulé.')));
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('Lancer l\'appel IA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _AiTag extends StatelessWidget {
  final String label;
  final Color color;

  const _AiTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
