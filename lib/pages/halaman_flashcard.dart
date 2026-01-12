import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../services/gemini_service.dart';
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Colors.white,
            title: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: "Lumora ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: "✨ Gemini",
                    style: TextStyle(
                      fontWeight: FontWeight
                          .w300, // Dibuat lebih tipis biar Lumora tetap dominan
                      fontSize:
                          25, // Ukurannya agak dikecilin dikit biar proporsional
                      color: Colors
                          .blue[200], // Kasih warna biru muda biar vibenya AI banget
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Flashcard Generator',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ubah materi sulit menjadi kartu belajar interaktif.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // --- Input Section ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Masukkan materi atau topik di sini...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 55, 71, 214),
                            Color.fromARGB(255, 4, 92, 192),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isLoading
                            ? const AnimatedDotsLoader(
                                text: "Sedang Mengerjakan",
                                color: Colors.white,
                              )
                            : const Text(
                                "Generate Flashcard",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- Flashcard Result ---
            if (flashcards.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Text(
                  output.isEmpty
                      ? "Belum ada flashcard. Ayo buat sekarang!"
                      : output,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'Kartu ${currentIndex + 1} dari ${flashcards.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // The Interactive Flip Card
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: FlipCard(
                      key: _flipCardKey,
                      direction: FlipDirection.HORIZONTAL,
                      front: _buildCardSide(
                        title: "PERTANYAAN",
                        content: flashcards[currentIndex]['question']!,
                        color: Colors.white,
                        textColor: const Color(0xFF1E3A8A),
                        subText: "Tap untuk lihat jawaban",
                      ),
                      back: _buildCardSide(
                        title: "JAWABAN",
                        content: flashcards[currentIndex]['answer']!,
                        color: const Color(0xFFE3F2FD),
                        textColor: Colors.blue.shade900,
                        subText: "Tap untuk kembali ke pertanyaan",
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Navigation Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavButton(
                        onPressed: currentIndex > 0 ? _prevCard : null,
                        icon: Icons.chevron_left,
                        label: "Prev",
                      ),
                      _buildNavButton(
                        onPressed: currentIndex < flashcards.length - 1
                            ? _nextCard
                            : null,
                        icon: Icons.chevron_right,
                        label: "Next",
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSide({
    required String title,
    required String content,
    required Color color,
    required Color textColor,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.1), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          SingleChildScrollView(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const Spacer(),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
      ),
    );
  }
}
