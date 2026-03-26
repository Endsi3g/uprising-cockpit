import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/lead.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const LeadCard({super.key, required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lead.estimatedValueCad != null)
                  Text(
                    lead.formattedValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                const SizedBox(height: 6),
                _StatusBadge(status: lead.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    switch (lead.jobType?.toLowerCase()) {
      case 'toiture':
      case 'toit':
        return Icons.roofing_outlined;
      case 'fuite':
      case 'plomberie':
        return Icons.water_drop_outlined;
      case 'gel':
      case 'gel/dégel':
        return Icons.ac_unit_outlined;
      default:
        return lead.source == LeadSource.sms
            ? Icons.sms_outlined
            : Icons.call_outlined;
    }
  }

  Color _iconColor() {
    switch (lead.status) {
      case LeadStatus.perdu:
        return AppColors.danger;
      case LeadStatus.booke:
      case LeadStatus.complete:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Color _iconBg() {
    switch (lead.status) {
      case LeadStatus.perdu:
        return AppColors.dangerSurface;
      case LeadStatus.booke:
      case LeadStatus.complete:
        return AppColors.successSurface;
      default:
        return AppColors.primarySurface;
    }
  }

  String _subtitle() {
    final time = _formatTime(lead.triggeredAt);
    final ai = lead.aiHandled ? 'IA a répondu en 2s' : 'Non géré par IA';
    final value = lead.estimatedValueCad != null
        ? ', estimation: ${lead.formattedValue}'
        : '';
    return '$time · $ai$value';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} à $h:$m';
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg(),
        ),
      ),
    );
  }

  Color _bg() {
    switch (status) {
      case LeadStatus.nouveau: return AppColors.badgeNewSurface;
      case LeadStatus.qualifie: return AppColors.warningSurface;
      case LeadStatus.booke: return AppColors.badgeBookedSurface;
      case LeadStatus.perdu: return AppColors.badgeLostSurface;
      case LeadStatus.complete: return AppColors.badgeCompletedSurface;
    }
  }

  Color _fg() {
    switch (status) {
      case LeadStatus.nouveau: return AppColors.badgeNew;
      case LeadStatus.qualifie: return AppColors.warning;
      case LeadStatus.booke: return AppColors.badgeBooked;
      case LeadStatus.perdu: return AppColors.badgeLost;
      case LeadStatus.complete: return AppColors.badgeCompleted;
    }
  }
}
