import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import 'package:flip_card/flip_card.dart';

class Flashcard extends StatefulWidget {
  final String? initialText;
  final bool autoGenerate;

  const Flashcard({super.key, this.initialText, this.autoGenerate = false});

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
  int currentIndex = 0;
  late GlobalKey<FlipCardState> _flipCardKey;

  @override
  void initState() {
    super.initState();
    _flipCardKey = GlobalKey<FlipCardState>();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      var cleaned = widget.initialText!.replaceAll(
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
        '',
      );
      cleaned = cleaned.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '');
      controller.text = cleaned;
    }
    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generate();
      });
    }
  }

  void goNext() {
    if (currentIndex < flashcards.length - 1) {
      // Reset flip card ke pertanyaan sebelum navigasi
      if (_flipCardKey.currentState?.isFront == false) {
        _flipCardKey.currentState?.toggleCard();
      }
      setState(() => currentIndex++);
    }
  }

  void goPrevious() {
    if (currentIndex > 0) {
      // Reset flip card ke pertanyaan sebelum navigasi
      if (_flipCardKey.currentState?.isFront == false) {
        _flipCardKey.currentState?.toggleCard();
      }
      setState(() => currentIndex--);
    }
  }

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

            // 📄 Hasilnya - Tampilan 1 kartu dengan navigasi kanan-kiri
            Expanded(
              child: flashcards.isEmpty
                  ? SingleChildScrollView(
                      child: Text(
                        output.isEmpty
                            ? "Belum ada flashcard. Masukkan materi dulu!"
                            : output,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Kartu besar tegak lurus
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: FlipCard(
                                key: _flipCardKey,
                                direction: FlipDirection.VERTICAL,
                                front: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.blue.shade50,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 300,
                                    ),
                                    padding: const EdgeInsets.all(24),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Pertanyaan",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          flashcards[currentIndex]['question']!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Tap untuk lihat jawaban",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                back: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.green.shade50,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 300,
                                    ),
                                    padding: const EdgeInsets.all(24),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Jawaban",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          flashcards[currentIndex]['answer']!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Tap untuk lihat pertanyaan",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Navigation dan counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Tombol kiri (previous)
                              ElevatedButton.icon(
                                onPressed: currentIndex > 0 ? goPrevious : null,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text("Sebelumnya"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),

                              // Counter
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${currentIndex + 1} / ${flashcards.length}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),

                              // Tombol kanan (next)
                              ElevatedButton.icon(
                                onPressed:
                                    currentIndex < flashcards.length - 1
                                        ? goNext
                                        : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text("Selanjutnya"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
