import 'dart:io';
import 'package:flutter/material.dart';
import 'flashcard_page.dart';
import '../widgets/tool_card.dart';
import 'summarizer_page.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? uploadedFileName;
  String? extractedText;

  String _sanitize(String s) {
    // remove control chars (except newline/tab) and surrogate code units
    var cleaned = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '');
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'AI Summarizer',
        'desc': 'Ringkas dokumen panjang jadi singkat & padat',
        'icon': Icons.article_outlined,
        'page': SummarizerPage(),
      },
      {
        'title': 'Flashcard Generator',
        'desc': 'Ubah materi jadi kartu belajar interaktif',
        'icon': Icons.style_outlined,
        'page': const Flashcard(),
      },
      {
        'title': 'Quiz Generator',
        'desc': 'Buat latihan soal otomatis dari teks',
        'icon': Icons.quiz_outlined,
        'page': null, // nanti kita isi
      },
      {
        'title': 'Explain Mode',
        'desc': 'Tanya konsep & penjelasan dari AI',
        'icon': Icons.psychology_alt_outlined,
        'page': null, // nanti juga
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black.withOpacity(0.1),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo_lumora.png', height: 28),
            const SizedBox(width: 10),

            const Text(
              'Lumora',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2050B4),
              Color(0xFF1A3F8A),
              Color(0xFF142F61),
              Color(0xFF0A182F),
              Color(0xFF000000),
            ],
          ),
        ),

        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 64, 16, 16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Selamat datang 👋",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pilih tools yang mau kamu pakai hari ini:",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),

            // Upload area: show button when no file, otherwise show filename
            if (uploadedFileName == null) ...[
              ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
              label: const Text(
                "Upload & Baca Dokumen PDF",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final file = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (file != null && file.files.single.path != null) {
                  final bytes = File(file.files.single.path!).readAsBytesSync();
                  final document = PdfDocument(inputBytes: bytes);

                  final text = PdfTextExtractor(document).extractText();
                  document.dispose();

                  setState(() {
                    uploadedFileName = file.files.single.name;
                    extractedText = _sanitize(text);
                  });
                }
              },
            ),
            ] else ...[
              // show uploaded filename with actions
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        uploadedFileName!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          uploadedFileName = null;
                          extractedText = null;
                        });
                      },
                      child: const Text('Ganti', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ],
            const SizedBox(height: 5),

            // GridView tetap sama
            GridView.builder(
              itemCount: tools.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final tool = tools[index];
                final Widget? page = tool['page'] as Widget?;

                return ToolCard(
                  title: tool['title'] as String,
                  description: tool['desc'] as String,
                  icon: tool['icon'] as IconData,
                  onTap: () {
                    // If tool has a page and we have extracted text, pass it via constructor
                    if (page != null) {
                      if (extractedText == null || extractedText!.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Silakan upload PDF terlebih dahulu.')),
                        );
                        return;
                      }

                      // Create the page and request it to auto-run processing when possible
                      Widget targetPage;
                      try {
                        targetPage = (page is SummarizerPage)
                            ? SummarizerPage(initialText: extractedText!, autoRun: true)
                            : (page is Flashcard)
                                ? Flashcard(initialText: extractedText!, autoGenerate: true)
                                : page;
                      } catch (_) {
                        targetPage = page;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => targetPage),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur ini masih coming soon 🚧'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
