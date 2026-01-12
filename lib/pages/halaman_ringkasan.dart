import '../services/gemini_service.dart';
import '../services/supabase_usage_limit_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lumora_app/widgets/animated_dots_loader.dart';
import '../services/file_parser.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class HalamanRingkas extends StatefulWidget {
  final String? initialText;
  final bool autoRun;

  const HalamanRingkas({super.key, this.initialText, this.autoRun = false});

  @override
  State<HalamanRingkas> createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<HalamanRingkas> {
  bool _inputTeks = true;
  String? _fileName;
  String? _fileContent;
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  bool _loading = false;

  static const int _maxUsagePerDay = 5;
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
    setState(() {
      _usageCount = 0;
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
      body: !_limitChecked
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'AI Summarizer',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ringkas teks panjang menjadi lebih singkat dan jelas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),

                  // Limit Warning
                  if (_usageCount >= _maxUsagePerDay)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Batas harian tercapai ($_usageCount/$_maxUsagePerDay). Coba lagi besok.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTabButton(
                              "Teks",
                              _inputTeks,
                              () => setState(() => _inputTeks = true),
                            ),
                            const SizedBox(width: 10),
                            _buildTabButton(
                              "File",
                              !_inputTeks,
                              () => setState(() => _inputTeks = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_inputTeks)
                          TextField(
                            controller: _controller,
                            maxLines: 6,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText:
                                  'Tempelkan teks atau masukkan artikel...',
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
                          )
                        else
                          Center(
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Pilih PDF / DOCX'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                if (_fileName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'File: $_fileName',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 55, 71, 214),
                                  Color.fromARGB(255, 4, 92, 192),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: _loading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      AnimatedDotsLoader(),
                                      SizedBox(width: 12),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: _ringkas,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      _inputTeks
                                          ? "Ringkas Teks"
                                          : "Ringkas Dokumen",
                                      style: const TextStyle(
                                        fontSize: 18,
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

                  if (_result.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Hasil Ringkasan:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: MarkdownBody(data: _result, selectable: true),
                    ),
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white30 : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileName = result.files.single.name;
          _loading = true;
        });
        final fileBytes = result.files.single.bytes!;
        final text = await FileParser.extractTextFromBytes(
          fileBytes,
          _fileName!,
        );

        setState(() {
          _controller.text = text;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membaca file: $e')));
    }
  }
}
