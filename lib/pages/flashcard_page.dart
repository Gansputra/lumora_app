import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import 'package:flip_card/flip_card.dart';

class Flashcard extends StatefulWidget {
  const Flashcard({super.key});

  @override
  State<Flashcard> createState() => _FlashcardState();
}

List<Map<String, String>> parseFlashcards(String raw) {
  final cards = <Map<String, String>>[];
  final entries = raw.split('###');

  for (var e in entries) {
    final questionMatch = RegExp(r'Q:\s*(.*)').firstMatch(e);
    final answerMatch = RegExp(r'A:\s*(.*)').firstMatch(e);

    if (questionMatch != null && answerMatch != null) {
      cards.add({
        'question': questionMatch.group(1)!.trim(),
        'answer': answerMatch.group(1)!.trim(),
      });
    }
  }
  return cards;
}

class _FlashcardState extends State<Flashcard> {
  final controller = TextEditingController();
  List<Map<String, String>> flashcards = [];
  String output = "";
  bool isLoading = false;

  generate() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final res = await AIService.generateResponse(text);
      final cards = parseFlashcards(res);

      setState(() {
        flashcards = cards;
        output = res;
      });
    } catch (e) {
      setState(() {
        output = "Error: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Flashcard Generator")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 📝 Tempat buat ngetik materi / prompt
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Masukkan materi di sini...",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // 🔘 Tombol Generate
            ElevatedButton(
              onPressed: isLoading ? null : generate,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Generate Flashcard"),
            ),
            const SizedBox(height: 12),

            // 📄 Hasilnya
            Expanded(
              child: flashcards.isEmpty
                  ? SingleChildScrollView(
                      child: Text(
                        output.isEmpty
                            ? "Belum ada flashcard. Masukkan materi dulu!"
                            : output,
                      ),
                    )
                  : ListView.builder(
                      itemCount: flashcards.length,
                      itemBuilder: (context, index) {
                        final card = flashcards[index];
                        return FlipCard(
                          direction: FlipDirection.HORIZONTAL,
                          front: Card(
                            color: Colors.blue.shade50,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              height: 120,
                              alignment: Alignment.center,
                              child: Text(
                                card['question']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          back: Card(
                            color: Colors.green.shade50,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              height: 120,
                              alignment: Alignment.center,
                              child: Text(
                                card['answer']!,
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
