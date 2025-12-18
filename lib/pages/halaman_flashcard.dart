import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:flip_card/flip_card.dart';
import 'package:lumora_app/widgets/animated_dots_loader.dart';

class FlashcardPage extends StatefulWidget {
  final String? initialText;
  final bool autoGenerate;

  const FlashcardPage({super.key, this.initialText, this.autoGenerate = false});

  @override
  State<FlashcardPage> createState() => _FlashcardState();
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

class _FlashcardState extends State<FlashcardPage> {
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
      controller.text = widget.initialText!;
      if (widget.autoGenerate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          generate();
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (currentIndex < flashcards.length - 1) {
      // Reset flip card to front (question) before changing card
      if (_flipCardKey.currentState?.isFront == false) {
        _flipCardKey.currentState?.toggleCard();
      }
      setState(() {
        currentIndex++;
      });
    }
  }

  void _prevCard() {
    if (currentIndex > 0) {
      // Reset flip card to front (question) before changing card
      if (_flipCardKey.currentState?.isFront == false) {
        _flipCardKey.currentState?.toggleCard();
      }
      setState(() {
        currentIndex--;
      });
    }
  }

  generate() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final res = await GeminiService.generateFlashcard(text);
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
                  ? const AnimatedDotsLoader(text: "Sedang Mengerjakan")
                  : const Text("Generate Flashcard"),
            ),
            const SizedBox(height: 12),

            // 📄 Flashcard Display - Single Card with Navigation
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Card Counter
                        Text(
                          'Kartu ${currentIndex + 1} dari ${flashcards.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Single Large FlipCard
                        Expanded(
                          child: FlipCard(
                            key: _flipCardKey,
                            direction: FlipDirection.HORIZONTAL,
                            front: Card(
                              color: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'PERTANYAAN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          flashcards[currentIndex]['question']!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tap untuk lihat jawaban',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            back: Card(
                              color: Colors.green.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'JAWABAN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          flashcards[currentIndex]['answer']!,
                                          style: const TextStyle(fontSize: 18),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tap untuk lihat pertanyaan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Navigation Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: currentIndex > 0 ? _prevCard : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Sebelumnya'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: currentIndex < flashcards.length - 1
                                  ? _nextCard
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Selanjutnya'),
                            ),
                          ],
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
