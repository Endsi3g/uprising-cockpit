import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/lead.dart';

class LeadRepository {
  final SupabaseClient _client;

  LeadRepository(this._client);

  Stream<List<Lead>> watchLeads({
    required String businessId,
    required String period, // 'today' | '7d' | '30d'
  }) {
    final since = _periodToDate(period);
    return _client
        .from(kTableLeads)
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .map((rows) {
          return rows
              .where((row) =>
                  DateTime.parse(row['triggered_at'] as String)
                      .isAfter(since))
              .map((row) => Lead.fromJson(row))
              .toList()
            ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
        });
  }

  Future<List<Lead>> fetchLeads({
    required String businessId,
    required String period,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
  }) async {
    final since = _periodToDate(period);
    var query = _client
        .from(kTableLeads)
        .select('*, clients(*)')
        .eq('business_id', businessId)
        .gte('triggered_at', since.toIso8601String());

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.name);
    }
    if (sourceFilter != null) {
      query = query.eq('source', sourceFilter.name);
    }

    final data = await query.order('triggered_at', ascending: false);
    return (data as List).map((e) => Lead.fromJson(e)).toList();
  }

  Future<Lead?> fetchLeadById(String id) async {
    final data = await _client
        .from(kTableLeads)
        .select('*, clients(*)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Lead.fromJson(data);
  }

  Future<void> updateStatus(String id, LeadStatus status) async {
    await _client
        .from(kTableLeads)
        .update({'status': status.name})
        .eq('id', id);
  }

  Future<void> updateSummary(String id, String summary) async {
    await _client
        .from(kTableLeads)
        .update({'summary': summary})
        .eq('id', id);
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
