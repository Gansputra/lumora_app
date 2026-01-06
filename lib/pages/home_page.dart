import 'dart:io';
import 'package:flutter/material.dart';
import 'halaman_flashcard.dart';
import '../widgets/tool_card.dart';
import 'halaman_ringkasan.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'halaman_qna.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  const HomePage({super.key, this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // PDF upload & extracted text logic dihapus, tools bisa langsung digunakan

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'AI Summarizer',
        'desc': 'Ringkas dokumen panjang jadi singkat & padat',
        'icon': Icons.article_outlined,
        'page': const halamanRingkas(),
      },
      {
        'title': 'Flashcard Generator',
        'desc': 'Ubah materi jadi kartu belajar interaktif',
        'icon': Icons.style_outlined,
        'page': const FlashcardPage(),
      },
      {
        'title': 'Quiz Generator',
        'desc': 'Buat latihan soal otomatis dari materi sekolah',
        'icon': Icons.quiz_outlined,
        'page': const QuestionGeneratorPage(),
      },
      {
        'title': 'Explain Mode',
        'desc': 'Tanya konsep & penjelasan dari AI',
        'icon': Icons.psychology_alt_outlined,
        'page': null, // nanti juga
      },
    ];

    final displayName = widget.userName != null && widget.userName!.isNotEmpty
        ? widget.userName!
        : null;
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
            Spacer(),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Pengaturan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
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
            Text(
              displayName != null
                  ? 'Selamat datang, $displayName'
                  : 'Selamat datang 👋',
              style: const TextStyle(
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
            // ListView vertikal untuk ToolCard
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: tools.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  final Widget? page = tool['page'] as Widget?;
                  return ToolCard(
                    title: tool['title'] as String,
                    description: tool['desc'] as String,
                    icon: tool['icon'] as IconData,
                    onTap: () {
                      if (page != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => page),
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
            ),
          ],
        ),
      ),
    );
  }
}
