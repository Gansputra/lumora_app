import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../services/supabase_usage_limit_service.dart';
import 'package:lumora_app/widgets/animated_dots_loader.dart';

// Import untuk PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuestionGeneratorPage extends StatefulWidget {
  const QuestionGeneratorPage({Key? key}) : super(key: key);

  @override
  State<QuestionGeneratorPage> createState() => _QuestionGeneratorPageState();
}

class _QuestionGeneratorPageState extends State<QuestionGeneratorPage> {
  int _jumlahPilihanGanda = 5;
  int _jumlahUraian = 1;
  bool _isLoading = false;
  String _result = "";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _materiController = TextEditingController();

  static const int _maxUsagePerDay = 5;
  int _usageCount = 0;
  bool _limitChecked = false;

  @override
  void dispose() {
    _materiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkUsageLimit();
  }

  Future<void> _checkUsageLimit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final count = await UsageLimitService.getTodayUsageCount(user.id);
      setState(() {
        _usageCount = count;
        _limitChecked = true;
      });
    } catch (e) {
      setState(() => _limitChecked = true);
    }
  }

  // --- FUNGSI EXPORT PDF ---
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                "LUMORA - AI Question Result",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Topik/Materi:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_materiController.text),
            pw.Divider(),
            pw.SizedBox(height: 10),
            // Kita bersihkan sedikit markdown agar tampil rapi di PDF standar
            pw.Text(_result.replaceAll('*', '').replaceAll('#', '')),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Lumora_QnA_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _submit() async {
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
          content: Text('Batas harian tercapai. Coba lagi besok.'),
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _result = "";
      });
      try {
        final materi = _materiController.text.trim();
        final res = await GeminiService.generateQnA(
          materi: materi,
          jumlahPilihanGanda: _jumlahPilihanGanda,
          jumlahIsian: _jumlahUraian,
        );
        await UsageLimitService.incrementUsage(user.id);
        setState(() {
          _result = res;
          _usageCount++;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
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
            title: const Text(
              "Lumora",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
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
                    'AI Question Maker',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buat latihan soal pilihan ganda dan uraian secara instan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),

                  if (_usageCount >= _maxUsagePerDay)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Batas penggunaan hari ini tercapai ($_usageCount/$_maxUsagePerDay).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Materi Soal",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _materiController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? 'Materi tidak boleh kosong'
                                : null,
                            decoration: InputDecoration(
                              hintText: "Tulis materi atau topik di sini...",
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: "Pilihan Ganda",
                                  value: _jumlahPilihanGanda,
                                  items: List.generate(6, (i) => 5 + i),
                                  onChanged: (val) => setState(
                                    () => _jumlahPilihanGanda = val!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildDropdownField(
                                  label: "Soal Uraian",
                                  value: _jumlahUraian,
                                  items: List.generate(5, (i) => 1 + i),
                                  onChanged: (val) =>
                                      setState(() => _jumlahUraian = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4FACFE),
                                    Color(0xFF00F2FE),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const AnimatedDotsLoader(
                                        text: 'Sedang Mengerjakan',
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Generate Soal',
                                        style: TextStyle(
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
                  ),

                  if (_result.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Hasil Soal & Jawaban:",
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
                      child: Column(
                        children: [
                          MarkdownBody(
                            data: _result,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 15, height: 1.5),
                              h2: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const Divider(height: 40),
                          // --- TOMBOL EXPORT PDF ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _exportToPDF,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("Export ke PDF"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E3A8A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              items: items
                  .map(
                    (i) => DropdownMenuItem(value: i, child: Text('$i Soal')),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
