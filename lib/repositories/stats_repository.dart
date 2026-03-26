import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/stats.dart';

class StatsRepository {
  final SupabaseClient _client;
  StatsRepository(this._client);

  Future<PeriodStats> fetchStats({
    required String businessId,
    required String period,
  }) async {
    final since = _periodToDate(period);

    // Fetch leads for period
    final leadsData = await _client
        .from(kTableLeads)
        .select('estimated_value_cad, status, ai_handled, missed_by_human, triggered_at')
        .eq('business_id', businessId)
        .gte('triggered_at', since.toIso8601String());

    final List<Map<String, dynamic>> leads = List<Map<String, dynamic>>.from(leadsData);

    // Aggregate
    final intercepted = leads
        .where((l) => l['ai_handled'] == true && l['missed_by_human'] == true)
        .toList();
    final lost = leads
        .where((l) => l['status'] == 'perdu')
        .toList();
    final booked = leads
        .where((l) => l['status'] == 'booke' || l['status'] == 'complete')
        .toList();

    final totalSaved = intercepted.fold<double>(
      0,
      (sum, l) => sum + ((l['estimated_value_cad'] as num?)?.toDouble() ?? 0),
    );

    // Build daily breakdown
    final Map<String, DailyStats> dailyMap = {};
    for (final lead in leads) {
      final date = DateTime.parse(lead['triggered_at'] as String);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final existing = dailyMap[key];
      final value = (lead['estimated_value_cad'] as num?)?.toDouble() ?? 0;
      final isIntercepted =
          lead['ai_handled'] == true && lead['missed_by_human'] == true;
      final isLost = lead['status'] == 'perdu';

      dailyMap[key] = DailyStats(
        date: DateTime(date.year, date.month, date.day),
        leadsIntercepted: (existing?.leadsIntercepted ?? 0) + (isIntercepted ? 1 : 0),
        leadsLost: (existing?.leadsLost ?? 0) + (isLost ? 1 : 0),
        savedCad: (existing?.savedCad ?? 0) + (isIntercepted ? value : 0),
        bookings: existing?.bookings ?? 0,
        responseTimeSeconds: 2.0, // TODO: calculate from calls table
      );
    }

    final dailyList = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return PeriodStats(
      totalSavedCad: totalSaved,
      totalLeadsIntercepted: intercepted.length,
      totalLeadsLost: lost.length,
      totalBookings: booked.length,
      avgResponseTimeSeconds: 2.0,
      conversionRate: intercepted.isEmpty
          ? 0
          : booked.length / intercepted.length * 100,
      daily: dailyList,
    );
  }

  DateTime _periodToDate(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }
}
