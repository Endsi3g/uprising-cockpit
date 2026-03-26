import '../core/constants.dart';
import 'client.dart';

class Lead {
  final String id;
  final String businessId;
  final String? clientId;
  final LeadSource source;
  final LeadStatus status;
  final double? estimatedValueCad;
  final bool aiHandled;
  final bool missedByHuman;
  final DateTime triggeredAt;
  final DateTime createdAt;
  final String? summary;
  final String? clientPhone;
  final String? clientAddress;
  final String? jobType; // ex: 'toiture', 'fuite', 'gel/dégel'
  final Client? client;

  Lead({
    required this.id,
    required this.businessId,
    this.clientId,
    required this.source,
    required this.status,
    this.estimatedValueCad,
    required this.aiHandled,
    required this.missedByHuman,
    required this.triggeredAt,
    required this.createdAt,
    this.summary,
    this.clientPhone,
    this.clientAddress,
    this.jobType,
    this.client,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientId: json['client_id'] as String?,
      source: LeadSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => LeadSource.call,
      ),
      status: LeadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeadStatus.nouveau,
      ),
      estimatedValueCad: (json['estimated_value_cad'] as num?)?.toDouble(),
      aiHandled: json['ai_handled'] as bool? ?? false,
      missedByHuman: json['missed_by_human'] as bool? ?? false,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      summary: json['summary'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientAddress: json['client_address'] as String?,
      jobType: json['job_type'] as String?,
      client: json['clients'] != null
          ? Client.fromJson(json['clients'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'client_id': clientId,
        'source': source.name,
        'status': status.name,
        'estimated_value_cad': estimatedValueCad,
        'ai_handled': aiHandled,
        'missed_by_human': missedByHuman,
        'triggered_at': triggeredAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'summary': summary,
        'client_phone': clientPhone,
        'client_address': clientAddress,
        'job_type': jobType,
      };

  Lead copyWith({
    String? id,
    String? businessId,
    String? clientId,
    LeadSource? source,
    LeadStatus? status,
    double? estimatedValueCad,
    bool? aiHandled,
    bool? missedByHuman,
    DateTime? triggeredAt,
    DateTime? createdAt,
    String? summary,
    String? clientPhone,
    String? clientAddress,
    String? jobType,
    Client? client,
  }) {
    return Lead(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      clientId: clientId ?? this.clientId,
      source: source ?? this.source,
      status: status ?? this.status,
      estimatedValueCad: estimatedValueCad ?? this.estimatedValueCad,
      aiHandled: aiHandled ?? this.aiHandled,
      missedByHuman: missedByHuman ?? this.missedByHuman,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
      summary: summary ?? this.summary,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      jobType: jobType ?? this.jobType,
      client: client ?? this.client,
    );
  }

  // Helpers
  String get displayTitle {
    final type = jobType != null
        ? jobType![0].toUpperCase() + jobType!.substring(1)
        : source.label;
    final city = clientAddress?.split(',').last.trim() ?? '';
    return '$type${city.isNotEmpty ? ' – $city' : ''}';
  }

  String get formattedValue {
    if (estimatedValueCad == null) return '–';
    return '${estimatedValueCad!.toStringAsFixed(0)} \$';
  }
}
