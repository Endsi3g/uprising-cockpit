class DailyStats {
  final DateTime date;
  final int leadsIntercepted;
  final int leadsLost;
  final double savedCad;
  final int bookings;
  final double responseTimeSeconds;

  DailyStats({
    required this.date,
    required this.leadsIntercepted,
    required this.leadsLost,
    required this.savedCad,
    required this.bookings,
    required this.responseTimeSeconds,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      leadsIntercepted: json['leads_intercepted'] as int? ?? 0,
      leadsLost: json['leads_lost'] as int? ?? 0,
      savedCad: (json['saved_cad'] as num?)?.toDouble() ?? 0.0,
      bookings: json['bookings'] as int? ?? 0,
      responseTimeSeconds:
          (json['response_time_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PeriodStats {
  final double totalSavedCad;
  final int totalLeadsIntercepted;
  final int totalLeadsLost;
  final int totalBookings;
  final double avgResponseTimeSeconds;
  final double conversionRate; // intercepted → booked
  final List<DailyStats> daily;

  PeriodStats({
    required this.totalSavedCad,
    required this.totalLeadsIntercepted,
    required this.totalLeadsLost,
    required this.totalBookings,
    required this.avgResponseTimeSeconds,
    required this.conversionRate,
    required this.daily,
  });

  String get formattedTotalSaved {
    if (totalSavedCad >= 1000) {
      return '${(totalSavedCad / 1000).toStringAsFixed(1)} k\$';
    }
    return '${totalSavedCad.toStringAsFixed(0)} \$';
  }

  String get formattedSavedFull {
    return '${totalSavedCad.toStringAsFixed(0)} \$ CAD';
  }
}
