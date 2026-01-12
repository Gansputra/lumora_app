import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  static String get _url =>
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey";
  static Future<String> generateQnA({
    required String materi,
    required int jumlahPilihanGanda,
    required int jumlahIsian,
  }) async {
    final prompt =
        '''Buat soal latihan dari materi berikut:
  - Pilihan ganda: $jumlahPilihanGanda soal
  - Isian singkat: $jumlahIsian soal
  - Bahasa Indonesia
  - Soal jelas, tidak ambigu
  - Jangan tambah teks di luar format
  PILIHAN GANDA:
  - 4 opsi (A–D), 1 benar
  - Soal ≤ 20 kata
  - Opsi ≤ 6 kata
  - Sertakan jawaban
  ISIAN SINGKAT:
  - Soal ≤ 20 kata
  - Jawaban ≤ 5 kata
  FORMAT:
  === PILIHAN GANDA ===
  1. Soal
  A. ...
  B. ...
  C. ...
  D. ...
  Jawaban: X
  === ISIAN SINGKAT ===
  1. Soal
  Jawaban: ...
  Materi:
  $materi''';
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );
      if (response.statusCode != 200) {
        throw Exception("HTTP Error: " + response.statusCode.toString());
      }
      final data = jsonDecode(response.body);
      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }
      return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
          "(No content)";
    } catch (e) {
      return "⚠️ Error generate QnA: $e";
    }
  }

  static Future<String> ringkasTeks(String prompt) async {
    print(
      '[GeminiService] Ringkas Teks dipanggil dengan prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}',
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

  static Future<String> jelaskanAwal(String topik) async {
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
Halo! 👋  
Sebagai tutor LUMORA, jelaskan $topik secara singkat dan santai.  
Gunakan analogi sederhana & emoji secukupnya, pakai format Markdown.  
Akhiri dengan satu pertanyaan untuk lanjut diskusi.""",
                },
              ],
            },
          ],
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return "⚠️ Gagal memulai penjelasan: $e";
    }
  }

  static Future<String> tanyaMateri({
    required String materi,
    required String pertanyaan,
  }) async {
    print('[GeminiService] Tanya Materi dipanggil');
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
Kamu adalah tutor LUMORA yang cerdas.

Materi utama:
$materi

Pertanyaan:
$pertanyaan

Jawab pertanyaan dengan bahasa ramah dan mudah dipahami.
Utamakan materi utama, tapi boleh pakai pengetahuan umum tambahan jika perlu (beri catatan singkat).
Gunakan format Markdown yang rapi.
""",
                },
              ],
            },
          ],
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return "⚠️ Gagal mengirim pesan: $e";
    }
  }

  static String _handleResponse(http.Response response) {
    if (response.statusCode == 429) {
      return "⚠️ Terlalu banyak permintaan (Rate Limit). Tunggu sebentar ya, bro.";
    }
    if (response.statusCode != 200) {
      return "⚠️ Terjadi kesalahan server (Error ${response.statusCode})";
    }
    final data = jsonDecode(response.body);
    return data["candidates"][0]["content"]["parts"][0]["text"]?.trim() ??
        "(No content)";
  }
}
