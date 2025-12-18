import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:lumora_app/widgets/animated_dots_loader.dart';

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

  @override
  void dispose() {
    _materiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _result = "";
      });
      final materi = _materiController.text.trim();
      final res = await GeminiService.generateQnA(
        materi: materi,
        jumlahPilihanGanda: _jumlahPilihanGanda,
        jumlahIsian: _jumlahUraian,
      );
      setState(() {
        _isLoading = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QnA Generator'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Buat Soal QnA',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Materi Soal",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
                                child: TextFormField(
                                  controller: _materiController,
                                  maxLines: 6,
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                      ? 'Materi tidak boleh kosong'
                                      : null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        "Tulis materi yang ingin dibuatkan soal...",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Jumlah Pilihan Ganda',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              DropdownButtonFormField<int>(
                                value: _jumlahPilihanGanda,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: List.generate(6, (i) => 5 + i)
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text('$val'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _jumlahPilihanGanda = val);
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Jumlah Soal Uraian',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              DropdownButtonFormField<int>(
                                value: _jumlahUraian,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: List.generate(5, (i) => 1 + i)
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text('$val'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _jumlahUraian = val);
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const Center(
                                        child: AnimatedDotsLoader(
                                          text: 'Sedang Mengerjakan',
                                          color: Colors.black,
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: const Text('Generate Soal'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_result.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
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
                        child: SelectableText(
                          _result,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
