import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead.dart';
import '../../models/transcript.dart';
import '../../repositories/lead_repository.dart';

final _leadDetailProvider =
    FutureProvider.family<Lead?, String>((ref, id) async {
  final repo = LeadRepository(SupabaseConfig.client);
  return repo.fetchLeadById(id);
});

final _transcriptProvider =
    FutureProvider.family<Transcript?, String>((ref, leadId) async {
  final data = await SupabaseConfig.client
      .from('transcripts')
      .select()
      .eq('lead_id', leadId)
      .maybeSingle();
  if (data == null) return null;
  return Transcript.fromJson(data);
});

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(_leadDetailProvider(leadId));
    final transcriptAsync = ref.watch(_transcriptProvider(leadId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail urgence'),
        actions: [
          leadAsync.whenOrNull(
            data: (lead) => lead != null
                ? PopupMenuButton<LeadStatus>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (status) async {
                      await LeadRepository(SupabaseConfig.client)
                          .updateStatus(leadId, status);
                      ref.invalidate(_leadDetailProvider(leadId));
                    },
                    itemBuilder: (_) => LeadStatus.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.label),
                            ))
                        .toList(),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: leadAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (lead) {
          if (lead == null) {
            return const Center(child: Text('Urgence introuvable'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                _SummaryCard(lead: lead),
                const SizedBox(height: 20),

                // Timeline
                _SectionHeader('Chronologie'),
                const SizedBox(height: 12),
                _TimelineWidget(lead: lead),
                const SizedBox(height: 20),

                // Transcript
                _SectionHeader('Transcription IA'),
                const SizedBox(height: 12),
                transcriptAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('—'),
                  data: (t) => t != null
                      ? _TranscriptCard(transcript: t)
                      : _noTranscript(),
                ),
                const SizedBox(height: 28),

                // Actions
                _ActionButtons(lead: lead),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _noTranscript() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textTertiary, size: 18),
            SizedBox(width: 10),
            Text('Aucune transcription disponible',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final Lead lead;
  const _SummaryCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.displayTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (lead.estimatedValueCad != null)
                Text(
                  lead.formattedValue,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (lead.clientAddress != null)
            _InfoRow(Icons.location_on_outlined, lead.clientAddress!),
          if (lead.client?.phone != null)
            _InfoRow(Icons.phone_outlined, lead.client!.phone!),
          if (lead.client?.name != null)
            _InfoRow(Icons.person_outline, lead.client!.name),
          _InfoRow(
              Icons.category_outlined,
              lead.source.label +
                  (lead.missedByHuman ? ' (manqué)' : ' (répondu)')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _TimelineWidget extends StatelessWidget {
  final Lead lead;
  const _TimelineWidget({required this.lead});

  @override
  Widget build(BuildContext context) {
    final events = [
      _Event(
        time: lead.triggeredAt,
        label: '${lead.source.label} entrant (non répondu)',
        icon: Icons.call_missed_outlined,
        color: AppColors.danger,
      ),
      _Event(
        time: lead.triggeredAt.add(const Duration(seconds: 2)),
        label: 'IA Uprising a répondu',
        icon: Icons.smart_toy_outlined,
        color: AppColors.primary,
      ),
      if (lead.status == LeadStatus.booke || lead.status == LeadStatus.complete)
        _Event(
          time: lead.triggeredAt.add(const Duration(minutes: 3)),
          label: 'RDV confirmé par l\'IA',
          icon: Icons.calendar_today,
          color: AppColors.success,
        ),
    ];

    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isLast = i == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: e.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(e.icon, size: 15, color: e.color),
                  ),
                  if (!isLast)
                    Container(
                        width: 2,
                        height: 28,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_formatTime(e.time),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} à $h:$m';
  }
}

class _Event {
  final DateTime time;
  final String label;
  final IconData icon;
  final Color color;
  const _Event(
      {required this.time,
      required this.label,
      required this.icon,
      required this.color});
}

class _TranscriptCard extends StatelessWidget {
  final Transcript transcript;
  const _TranscriptCard({required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transcript.summary != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(transcript.summary!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...transcript.messages.map((msg) => _MessageBubble(msg: msg)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TranscriptMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isAi = msg.role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              color: isAi ? AppColors.primarySurface : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAi ? Icons.smart_toy_outlined : Icons.person_outline,
              size: 13,
              color: isAi ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAi ? 'IA Uprising' : 'Client',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAi
                            ? AppColors.primary
                            : AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(msg.text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Lead lead;
  const _ActionButtons({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (lead.client?.phone != null) ...[
          ElevatedButton.icon(
            onPressed: () => _call(lead.client!.phone!),
            icon: const Icon(Icons.phone),
            label: const Text('Appeler le client'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _sendEnRouteSms(lead.client!.phone!),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('SMS : "Je suis en route"'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Voir le calendrier'),
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border)),
        ),
      ],
    );
  }

  void _call(String phone) {
    launchUrl(Uri.parse('tel:$phone'));
  }

  void _sendEnRouteSms(String phone) {
    final msg = Uri.encodeComponent(
        "Bonjour, c'est l'équipe Uprising. Notre technicien est en route et arrivera sous peu pour votre urgence.");
    launchUrl(Uri.parse('sms:$phone?body=$msg'));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}
