import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';
import '../services/supabase_usage_limit_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/animated_dots_loader.dart';

class ExplainPage extends StatefulWidget {
  const ExplainPage({super.key});

  @override
  State<ExplainPage> createState() => _ExplainPageState();
}

class _ExplainPageState extends State<ExplainPage> {
  bool _isChatMode = false;
  bool _loading = false;
  final TextEditingController _materiController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  String _contextMateri = "";
  final List<Map<String, dynamic>> _messages = [];

  Future<void> _startLearning() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu.')),
      );
      return;
    }

    final topic = _materiController.text.trim();
    if (topic.isEmpty) return;

    setState(() => _loading = true);

    try {
      _contextMateri = topic;
      final response = await GeminiService.jelaskanAwal(topic);

      await UsageLimitService.incrementUsage(user.id);

      setState(() {
        _isChatMode = true;
        _messages.add({"role": "bot", "message": response});
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Waduh, ada error pas mulai: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendChat() async {
    final ask = _chatController.text.trim();
    if (ask.isEmpty || _loading) return;

    setState(() {
      _messages.add({"role": "user", "message": ask});
      _chatController.clear();
      _loading = true;
    });

    try {
      final response = await GeminiService.tanyaMateri(
        materi: _contextMateri,
        pertanyaan: ask,
      );

      setState(() => _messages.add({"role": "bot", "message": response}));
    } catch (e) {
      setState(
        () => _messages.add({
          "role": "bot",
          "message": "Maaf bro, sepertinya ada masalah koneksi: $e",
        }),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Agar gradient di flexibleSpace terlihat
        elevation: 0,
        leading: _isChatMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _isChatMode = false;
                  _messages.clear();
                }),
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isChatMode ? _contextMateri : "LUMORA Tutor",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18, // Ukuran sedikit disesuaikan
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            // --- SUBTITLE BRANDING ---
            Text(
              "✨ Gemini AI",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isChatMode ? _buildChatLayout() : _buildSimpleInput(),
      ),
    );
  }

  Widget _buildSimpleInput() {
    return Center(
      key: const ValueKey(1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text(
              "Halo! Aku LUMORA.",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Siap jadi teman belajarmu hari ini.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mau bahas apa hari ini?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _materiController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mau Bahasa Apa Hari Ini?',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatLayout() {
    return Column(
      key: const ValueKey(2),
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _messages.length,
            itemBuilder: (context, index) => ChatBubble(
              message: _messages[index]['message'],
              isBot: _messages[index]['role'] == 'bot',
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AnimatedDotsLoader(
              text: "LUMORA sedang berpikir",
              color: Color(0xFF1E3C72),
            ),
          ),
        _buildBottomInput(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
        child: ElevatedButton(
          onPressed: _loading ? null : _startLearning,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Mulai Belajar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: "Tanya materinya...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF1E3C72),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendChat,
            ),
          ),
        ],
      ),
    );
  }
}
