import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$kGroqBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': kGroqModel,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw GroqException('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      throw GroqException('Failed to reach Groq: $e');
    }
  }

  Future<String> summarizeLead({
    required String clientName,
    required String transcript,
    required String tradeType,
  }) async {
    return chat([
      {
        'role': 'system',
        'content':
            'Tu es un assistant pour une entreprise de $tradeType au Québec. '
            'Résume de façon concise (2-3 lignes max, en français) la demande d\'un client '
            'basée sur la transcription d\'un appel. Inclus: le problème principal, '
            'la valeur estimée si mentionnée, et le statut (booké/non).',
      },
      {
        'role': 'user',
        'content': 'Client: $clientName\nTranscription:\n$transcript',
      },
    ]);
  }

  Future<String> analyzeStats({
    required Map<String, dynamic> statsData,
    required String businessName,
  }) async {
    return chat([
      {
        'role': 'system',
        'content':
            'Tu es un analyste business pour $businessName, une entreprise de services à domicile au Québec. '
            'Analyse les statistiques fournies et donne des insights actionnables en français. '
            'Sois concis et pratique.',
      },
      {
        'role': 'user',
        'content': 'Voici mes stats: ${jsonEncode(statsData)}. '
            'Qu\'est-ce que tu remarques et que devrais-je améliorer?',
      },
    ]);
  }
}

class GroqException implements Exception {
  final String message;
  GroqException(this.message);

  @override
  String toString() => 'GroqException: $message';
}
