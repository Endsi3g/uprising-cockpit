import '../core/constants.dart';

class Booking {
  final String id;
  final String? leadId;
  final String? clientId;
  final String businessId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? jobType;
  final String? address;
  final String? notes;
  final BookingStatus status;
  final double? estimatedValueCad;
  final String? clientName;
  final String? clientPhone;

  Booking({
    required this.id,
    this.leadId,
    this.clientId,
    required this.businessId,
    required this.scheduledAt,
    required this.durationMinutes,
    this.jobType,
    this.address,
    this.notes,
    required this.status,
    this.estimatedValueCad,
    this.clientName,
    this.clientPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      leadId: json['lead_id'] as String?,
      clientId: json['client_id'] as String?,
      businessId: json['business_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      jobType: json['job_type'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.planifie,
      ),
      estimatedValueCad: (json['estimated_value_cad'] as num?)?.toDouble(),
      clientName: json['client_name'] as String?,
      clientPhone: json['client_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lead_id': leadId,
        'client_id': clientId,
        'business_id': businessId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'job_type': jobType,
        'address': address,
        'notes': notes,
        'status': status.name,
        'estimated_value_cad': estimatedValueCad,
        'client_name': clientName,
        'client_phone': clientPhone,
      };

  String get formattedTime {
    final h = scheduledAt.hour.toString().padLeft(2, '0');
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedValue {
    if (estimatedValueCad == null) return '–';
    return '${estimatedValueCad!.toStringAsFixed(0)} \$';
  }
}
