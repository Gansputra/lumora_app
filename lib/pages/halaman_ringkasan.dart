import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/supabase_usage_limit_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lumora_app/widgets/animated_dots_loader.dart';
import '../services/file_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class halamanRingkas extends StatefulWidget {
  final String? initialText;
  final bool autoRun;

  const halamanRingkas({super.key, this.initialText, this.autoRun = false});

  @override
  State<halamanRingkas> createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<halamanRingkas> {
  bool _inputTeks = true; // true: input teks, false: upload file
  String? _fileName;
  String? _fileContent;
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  bool _loading = false;

  static const int _maxUsagePerDay = 2;
  int _usageCount = 0;
  bool _limitChecked = false;

  @override
  void initState() {
    super.initState();
    _checkUsageLimit();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
      if (widget.autoRun) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ringkas();
        });
      }
    }
  }

  Future<void> _checkUsageLimit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final count = await UsageLimitService.getTodayUsageCount(user.id);
    setState(() {
      _usageCount = count;
      _limitChecked = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ringkas() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menggunakan fitur ini.'),
        ),
      );
      return;
    }
    if (_usageCount >= _maxUsagePerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas penggunaan Summarizer hari ini sudah tercapai.'),
        ),
      );
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final res = await GeminiService.ringkasTeks(text);
      await UsageLimitService.incrementUsage(user.id);
      setState(() {
        _result = res;
        _usageCount++;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }
  /*******  c9bf4405-0da5-4cae-ba5b-c1328d942218  *******/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("AI Summarizer"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: !_limitChecked
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_usageCount >= _maxUsagePerDay)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Batas penggunaan Summarizer hari ini sudah tercapai (5x). Coba lagi besok.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Input Teks'),
                        selected: _inputTeks,
                        onSelected: (val) {
                          setState(() => _inputTeks = true);
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Upload PDF/DOC'),
                        selected: !_inputTeks,
                        onSelected: (val) {
                          setState(() => _inputTeks = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_inputTeks) ...[
                    const Text(
                      "Masukkan teks yang mau diringkas:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Tulis atau paste teks di sini...",
                        ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Ambil file PDF/DOCX dari user
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'docx'],
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            setState(() {
                              _fileName = result.files.single.name;
                              _fileContent = null;
                              _controller.text = '';
                            });
                            // Parsing file
                            final text = await FileParser.extractText(file);
                            setState(() {
                              _fileContent = text;
                              _controller.text = text;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membaca file: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pilih File PDF/DOC'),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 8),
                      Text('File: $_fileName'),
                    ],
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _ringkas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const AnimatedDotsLoader(
                              text: 'Sedang Mengerjakan',
                              color: Colors.white,
                            )
                          : Text(
                              _inputTeks ? "Ringkas Teks" : "Ringkas Dokumen",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_result.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Markdown(
                          data: _result,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.5),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            h1: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
