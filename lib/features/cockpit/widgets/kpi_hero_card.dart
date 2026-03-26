import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/stats.dart';
import 'savings_counter.dart';

class KpiHeroCard extends StatelessWidget {
  final PeriodStats stats;
  final String period;

  const KpiHeroCard({super.key, required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        // STRICTLY 0 elevation per minimalist-ui rules
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _periodLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SavingsCounter(targetValue: stats.totalSavedCad),
          const SizedBox(height: 4),
          const Text(
            'sauvés par l\'IA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip(
                Icons.phone_in_talk_outlined,
                '${stats.totalLeadsIntercepted}',
                'interceptés',
              ),
              const SizedBox(width: 12),
              _statChip(
                Icons.calendar_today_outlined,
                '${stats.totalBookings}',
                'bookés',
              ),
              const SizedBox(width: 12),
              _statChip(
                Icons.trending_up,
                '${stats.conversionRate.toStringAsFixed(0)}%',
                'conversion',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel() {
    switch (period) {
      case 'today':
        return "Aujourd'hui";
      case '7d':
        return '7 derniers jours';
      case '30d':
        return '30 derniers jours';
      default:
        return '30 jours';
    }
  }
}
