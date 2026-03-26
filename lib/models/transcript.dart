class TranscriptMessage {
  final String role; // 'ai' | 'client'
  final String text;
  final DateTime? timestamp;

  TranscriptMessage({
    required this.role,
    required this.text,
    this.timestamp,
  });

  factory TranscriptMessage.fromJson(Map<String, dynamic> json) {
    return TranscriptMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: json['ts'] != null ? DateTime.parse(json['ts'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'ts': timestamp?.toIso8601String(),
      };
}

class Transcript {
  final String id;
  final String leadId;
  final List<TranscriptMessage> messages;
  final String? summary;
  final String? aiModel;
  final DateTime createdAt;

  Transcript({
    required this.id,
    required this.leadId,
    required this.messages,
    this.summary,
    this.aiModel,
    required this.createdAt,
  });

  factory Transcript.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    List<TranscriptMessage> msgs = [];
    if (content is List) {
      msgs = content
          .map((e) => TranscriptMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return Transcript(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      messages: msgs,
      summary: json['summary'] as String?,
      aiModel: json['ai_model'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
