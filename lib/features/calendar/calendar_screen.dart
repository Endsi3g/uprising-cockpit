import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';

final _selectedDayProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final _bookingsProvider =
    FutureProvider.family<List<Booking>, DateTime>((ref, date) {
  final repo = BookingRepository(SupabaseConfig.client);
  return repo.fetchByDate(businessId: kDevBusinessId, date: date);
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(_selectedDayProvider);
    final bookingsAsync = ref.watch(_bookingsProvider(selectedDay));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text('Calendrier',
                  style: Theme.of(context).textTheme.headlineLarge),
            ),

            // Week picker
            _WeekPicker(
              selectedDay: selectedDay,
              onDaySelected: (d) =>
                  ref.read(_selectedDayProvider.notifier).state = d,
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: AppColors.border, height: 1),
            ),
            const SizedBox(height: 16),

            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _formatDate(selectedDay),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),

            // Bookings list
            Expanded(
              child: bookingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 48, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text('Aucune intervention ce jour',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _BookingCard(booking: bookings[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    final isToday = _isSameDay(d, DateTime.now());
    final prefix = isToday ? "Aujourd'hui · " : '';
    return '$prefix${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekPicker extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekPicker(
      {required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final days =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14, // 2 weeks
        itemBuilder: (ctx, i) {
          final d = startOfWeek.add(Duration(days: i - 7));
          final selected = _isSameDay(d, selectedDay);
          final isToday = _isSameDay(d, now);
          return GestureDetector(
            onTap: () => onDaySelected(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              width: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday && !selected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    labels[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  booking.formattedTime,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${booking.durationMinutes}min',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.jobType ?? 'Intervention',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (booking.address != null)
                  Text(booking.address!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (booking.clientName != null)
                  Text(booking.clientName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (booking.estimatedValueCad != null)
            Text(
              booking.formattedValue,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}
