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

            // Month picker
            _MonthPicker(
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

class _MonthPicker extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _MonthPicker({required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    // Top row for month navigation
    final currentMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    final lastDayOfMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0);
    
    final leadingDays = firstDayOfMonth.weekday - 1;
    final totalDays = lastDayOfMonth.day;
    
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];

    return Column(
      children: [
        // Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDaySelected(DateTime(selectedDay.year, selectedDay.month - 1, 1)),
              ),
              Text('${months[currentMonth.month - 1]} ${currentMonth.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onDaySelected(DateTime(selectedDay.year, selectedDay.month + 1, 1)),
              ),
            ],
          ),
        ),
        // Weekday labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((l) => SizedBox(
              width: 30,
              child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )).toList(),
          ),
        ),
        // Grid
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: leadingDays + totalDays,
          itemBuilder: (ctx, i) {
            if (i < leadingDays) return const SizedBox.shrink();
            
            final day = i - leadingDays + 1;
            final d = DateTime(selectedDay.year, selectedDay.month, day);
            final selected = _isSameDay(d, selectedDay);
            final isToday = _isSameDay(d, DateTime.now());
            
            return GestureDetector(
              onTap: () => onDaySelected(d),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : (isToday ? AppColors.surface : Colors.transparent),
                  shape: BoxShape.circle,
                  border: isToday && !selected ? Border.all(color: AppColors.primary) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
    return GestureDetector(
      onTap: () => context.push('/bookings/${booking.id}'),
      child: Container(
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
      ),
    );
  }
}
