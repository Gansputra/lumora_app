import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  static String get _url =>
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey";

  /// SUMMARIZER NORMAL
  static Future<String> summarizeText(String prompt) async {
    print(
      '[GeminiService] summarizeText dipanggil dengan prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}',
    );
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
Ringkas teks berikut menjadi versi paling jelas, padat, dan mudah dipahami.
Gunakan bahasa natural ,Jika teks panjang, pecah jadi paragraf,Jangan lupa beri emoji yang relevan, tetapi jangan berlebihan,output harus di awali dengan \"INI DIA HASIL RINGKASANYA, SEMOGA MEMBANTU!\",Semisal ada yang tidak relevan dengan tema yang diberikan tidak perlu di keluarkan
Teks: $prompt
""",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 429) {
        return "⚠️ Terlalu banyak permintaan ke server. Silakan tunggu beberapa detik dan coba lagi.";
      }
      if (response.statusCode != 200) {
        throw Exception("HTTP Error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }

      return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
          "(No content)";
    } catch (e) {
      return "⚠️ Gagal meringkas teks: $e";
    }
  }

  /// SUMMARIZER Markdown
  static Future<String> summarizeMarkdown(String prompt) async {
    print(
      '[GeminiService] summarizeMarkdown dipanggil dengan prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}',
    );
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
Ringkas teks berikut menjadi markdown yang rapi.

Format:
- Gunakan paragraf pendek
- Gunakan **bold** untuk istilah penting
- Pakai bullet list kalau perlu
- Hindari bahasa bertele-tele

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

      if (response.statusCode != 200) {
        throw Exception("HTTP Error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }

      return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
          "(No content)";
    } catch (e) {
      return "⚠️ Gagal meringkas teks (Markdown): $e";
    }
  }

  /// FLASHCARD GENERATOR
  static Future<String> generateFlashcard(String prompt) async {
    print(
      '[GeminiService] generateFlashcard dipanggil dengan prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}',
    );
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
pisahkan dengan ###
Teks:
$prompt
""",
                },
              ],
            },
          ],
        }),
      );
      if (response.statusCode != 200) {
        throw Exception("HTTP Error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }
      return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
          "(No content)";
    } catch (e) {
      return "⚠️ Error: $e";
    }
  }
}
