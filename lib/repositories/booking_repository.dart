import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/booking.dart';

class BookingRepository {
  final SupabaseClient _client;
  BookingRepository(this._client);

  Future<List<Booking>> fetchByDate({
    required String businessId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final data = await _client
        .from(kTableBookings)
        .select()
        .eq('business_id', businessId)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at');

    return (data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Booking>> fetchByWeek({
    required String businessId,
    required DateTime weekStart,
  }) async {
    final end = weekStart.add(const Duration(days: 7));

    final data = await _client
        .from(kTableBookings)
        .select()
        .eq('business_id', businessId)
        .gte('scheduled_at', weekStart.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at');

    return (data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> fetchById(String id) async {
    final data = await _client
        .from(kTableBookings)
        .select()
        .eq('id', id)
        .single();
    return Booking.fromJson(data);
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _client
        .from(kTableBookings)
        .update({'status': status.name})
        .eq('id', id);
  }

  Future<String> createBooking(Map<String, dynamic> data) async {
    final result = await _client
        .from(kTableBookings)
        .insert(data)
        .select('id')
        .single();
    return result['id'] as String;
  }
}
