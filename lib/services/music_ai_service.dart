import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_keys.dart';

class MusicAiService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> askMusicAssistant({
    required String question,
    required List<Map<String, dynamic>> history,
  }) async {
    if (ApiKeys.openRouterApiKey.trim().isEmpty ||
        ApiKeys.openRouterApiKey == 'ISI_API_KEY_OPENROUTER_KAMU_DI_SINI') {
      throw Exception('API key OpenRouter belum diisi.');
    }

    final chatHistory = history
        .where((message) {
          final role = message['role']?.toString();
          final text = message['text']?.toString();
          return (role == 'user' || role == 'assistant') &&
              text != null &&
              text.trim().isNotEmpty;
        })
        .take(12)
        .map((message) {
          return {
            'role': message['role'] == 'user' ? 'user' : 'assistant',
            'content': message['text'].toString(),
          };
        })
        .toList();

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer ${ApiKeys.openRouterApiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://pitch-perfect.local',
        'X-Title': 'Pitch Perfect',
      },
      body: jsonEncode({
        'model': 'openrouter/free',
        'messages': [
          {
            'role': 'system',
            'content':
                'Kamu adalah Music Assistant di aplikasi Pitch Perfect. Jawab dalam bahasa Indonesia yang natural, ramah, dan tidak kaku. Kamu bisa ngobrol santai, membalas sapaan seperti hai/halo, menjawab pertanyaan musik, rekomendasi lagu, latihan vokal, gitar, tuning, solfege Do Re Mi, pemanasan suara, dan tips belajar musik. Jawaban harus sesuai pertanyaan user, jangan mengulang jawaban yang sama terus. Kalau user bertanya lagu lokal, Jawa, koplo, pop Indonesia, atau artis seperti Aftershine, Guyon Waton, Denny Caknan, NDX AKA, Happy Asmara, berikan rekomendasi yang relevan dan alasan singkat. Jika user bertanya cara latihan, beri langkah praktis. Jangan mengaku bisa memutar lagu penuh, cukup arahkan ke preview jika tersedia.',
          },
          ...chatHistory,
          {'role': 'user', 'content': question},
        ],
        'temperature': 0.85,
        'max_tokens': 700,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'OpenRouter gagal menjawab. Status: ${response.statusCode}. ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final choices = decoded['choices'];

    if (choices is List && choices.isNotEmpty) {
      final message = choices.first['message'];
      if (message is Map && message['content'] != null) {
        final answer = message['content'].toString().trim();
        if (answer.isNotEmpty) return answer;
      }
    }

    throw Exception('Jawaban AI kosong.');
  }
}
