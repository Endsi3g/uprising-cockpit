import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (client) {
          if (client == null) return const Center(child: Text('Client introuvable'));
          
          final initials = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

          return CustomScrollView(
            slivers: [
              // Premium Glass Header with Avatar
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Vibrant Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [AppColors.primary, Color(0xFF0033FF)],
                          ),
                        ),
                      ),
                      // Glass Overlay for Name/Avatar
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.primarySurface,
                                child: Text(initials, style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.w900)),
                              ),
                            ).animate().scale(curve: Curves.elasticOut, duration: 800.milliseconds),
                            const SizedBox(height: 16),
                            Text(
                              client.name,
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ).animate().fadeIn(delay: 200.milliseconds).slideY(begin: 0.2),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                              child: const Text('CLIENT VIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ).animate().fadeIn(delay: 400.milliseconds),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CircularAction(icon: Icons.phone_outlined, label: 'Appeler', onTap: () => _launchUrl('tel:${client.phone}')),
                          _CircularAction(icon: Icons.chat_bubble_outline, label: 'SMS', onTap: () => _launchUrl('sms:${client.phone}')),
                          _CircularAction(icon: Icons.mail_outline, label: 'Email', onTap: () => _launchUrl('mailto:${client.email}')),
                          _CircularAction(icon: Icons.message_outlined, label: 'WhatsApp', onTap: () => _launchUrl('https://wa.me/${client.phone}')),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.2),

                      const SizedBox(height: 40),

                      // Coordinates Card
                      _DetailSection(
                        title: 'Coordonnées',
                        children: [
                          _DetailRow(icon: Icons.phone_android, label: 'Téléphone', value: client.phone ?? 'Non spécifié'),
                          _DetailRow(icon: Icons.location_on_outlined, label: 'Adresse', value: client.address ?? 'Non spécifiée'),
                          _DetailRow(icon: Icons.map_outlined, label: 'Ville', value: client.city ?? 'Non spécifiée'),
                          _DetailRow(icon: Icons.email_outlined, label: 'Email', value: client.email ?? 'Non spécifié'),
                        ],
                      ).animate(delay: 100.milliseconds).fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // AI Analysis Card
                      _DetailSection(
                        title: 'Analyse IA & Insights',
                        isAccent: true,
                        children: [
                          const _AiInsight(
                            text: 'Client récurrent avec une haute réactivité. Préfère les interventions le matin.',
                            icon: Icons.auto_awesome,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _TechTag(label: 'VIP', color: AppColors.secondary),
                              _TechTag(label: 'URGENT', color: AppColors.error),
                              _TechTag(label: 'RÉSIDENTIEL', color: AppColors.primary),
                            ],
                          ),
                        ],
                      ).animate(delay: 300.milliseconds).fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Bland AI Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                _VoiceRing(),
                                SizedBox(width: 16),
                                Text('Assistant Bland AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Lancer un appel de qualification intelligent pour ce client.',
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Initialisation Bland AI...')));
                                },
                                child: const Text('Déclencher l\'appel vocal', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 500.milliseconds).fadeIn().scale(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CircularAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.primary),
          padding: const EdgeInsets.all(16),
          style: IconButton.styleFrom(backgroundColor: AppColors.primarySurface),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isAccent;
  const _DetailSection({required this.title, required this.children, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isAccent ? AppColors.primary.withOpacity(0.2) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiInsight extends StatelessWidget {
  final String text;
  final IconData icon;
  const _AiInsight({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.5)),
        ),
      ],
    );
  }
}

class _TechTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TechTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}

class _VoiceRing extends StatelessWidget {
  const _VoiceRing();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(1, 1), end: const Offset(2.5, 2.5), duration: 2.seconds)
            .fadeOut(),
        const Icon(Icons.mic, color: Colors.white, size: 24),
      ],
    );
  }
}
