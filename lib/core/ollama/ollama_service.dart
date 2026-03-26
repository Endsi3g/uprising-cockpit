import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class OllamaService {
  static final OllamaService _instance = OllamaService._internal();
  factory OllamaService() => _instance;
  OllamaService._internal();

  String get _baseUrl => dotenv.env['OLLAMA_BASE_URL'] ?? kOllamaBaseUrl;
  bool _available = false;

  Future<bool> checkAvailability() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 3));
      _available = response.statusCode == 200;
      return _available;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  Future<String> generate(String prompt) async {
    if (!_available) {
      final ok = await checkAvailability();
      if (!ok) throw OllamaException('Ollama non disponible localement.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': kOllamaModel,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    } else {
      throw OllamaException('Ollama error: ${response.statusCode}');
    }
  }

  bool get isAvailable => _available;
}

class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
