import 'package:flutter/material.dart';
import 'flashcard_page.dart';
import '../widgets/tool_card.dart';
import 'summarizer_page.dart';
import 'dart:ui';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            // Logo di kiri
            Image.asset(
              'assets/images/logo_lumora.png', // ganti path sesuai punya lu
              height: 28,
            ),
            const SizedBox(width: 10),

            // Tulisan "Lumora"
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
          ],
        ),
      ),
    );
  }
}
