import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  static String get _url =>
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey";

  static Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      """
Kamu akan membuat flashcard dari teks berikut.

Langkah:
1. Ringkas teks jadi poin penting
2. Buat flashcard Q&A
3. Format:
Q: ...
A: ...
Pisahkan dengan ###

Teks:
---
$prompt
---
""",
                },
              ],
            },
          ],
        }),
      );

      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
          "(No content)";
    } catch (e) {
      return "⚠️ Error: $e";
    }
  }
}
