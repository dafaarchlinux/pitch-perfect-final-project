import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';

class MusicAiService {
  static String _limitMessage() {
    return 'Maaf, AI Coach sedang mencapai limit. Coba beberapa saat lagi.';
  }

  static Future<String> askMusicAssistant({
    required String question,
    required List<Map<String, dynamic>> history,
  }) async {
    final apiKey = ApiKeys.groqApiKey.trim();

    if (apiKey.isEmpty || apiKey == 'TEMPEL_GROQ_KEY_KAMU_DI_SINI') {
      return _limitMessage();
    }

    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content':
              'Kamu adalah AI Music Coach di aplikasi Pitch Perfect. Jawab dalam bahasa Indonesia yang natural, singkat, jelas, dan praktis. Fokus hanya pada latihan vokal, stem gitar, teori musik dasar, solfege Do Re Mi, ear training, jadwal latihan, dan rekomendasi latihan berdasarkan progres. Jangan terlalu panjang. Gunakan poin jika membantu. Jangan mengaku bisa memutar lagu penuh.',
        },
        ...history
            .where((item) {
              final role = item['role']?.toString();
              final text = item['text']?.toString().trim() ?? '';
              return text.isNotEmpty &&
                  (role == 'user' || role == 'assistant' || role == 'ai');
            })
            .take(8)
            .map((item) {
              final role = item['role']?.toString() == 'user'
                  ? 'user'
                  : 'assistant';

              return {'role': role, 'content': item['text'].toString()};
            }),
        {'role': 'user', 'content': question},
      ];

      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': ApiKeys.groqModel,
              'messages': messages,
              'temperature': 0.75,
              'max_tokens': 700,
            }),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _limitMessage();
      }

      final decoded = jsonDecode(response.body);
      final choices = decoded['choices'];

      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;

        if (first is Map) {
          final message = first['message'];

          if (message is Map) {
            final content = message['content']?.toString().trim() ?? '';

            if (content.isNotEmpty) {
              return content;
            }
          }
        }
      }

      return _limitMessage();
    } catch (_) {
      return _limitMessage();
    }
  }
}
