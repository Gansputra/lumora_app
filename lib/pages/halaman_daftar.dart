import 'dart:ui';

import 'package:lumora_app/pages/halaman_masuk.dart';
import 'package:lumora_app/pages/halaman_utama.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanDaftar extends StatefulWidget {
  const HalamanDaftar({Key? key}) : super(key: key);

  @override
  State<HalamanDaftar> createState() => _HalamanDaftarState();
}

class _HalamanDaftarState extends State<HalamanDaftar> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    void showPopup(String title, String message, {bool success = false}) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            title,
            style: TextStyle(color: success ? Colors.green : Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showPopup('Error', 'Semua field harus diisi');
      return;
    }

    if (password != confirm) {
      showPopup('Error', 'Password tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      final emailVerified = res.user?.emailConfirmedAt != null;

      if (user == null) {
        showPopup('Gagal', 'Gagal mendaftar');
        return;
      }

      if (!emailVerified) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Verifikasi Email',
              style: TextStyle(color: Colors.orange),
            ),
            content: const Text(
              'Pendaftaran berhasil!\n\nSilakan cek email Anda dan lakukan verifikasi sebelum login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HalamanMasuk()),
        );
        return;
      }

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'username': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil', style: TextStyle(color: Colors.green)),
          content: const Text('Pendaftaran berhasil'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HalamanMasuk()),
      );
    } catch (e) {
      showPopup('Error', 'Terjadi error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: Container(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/daun.png',
                            ), // Ganti dengan gambar daun
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.blue.shade700.withOpacity(0.6),
                              BlendMode.srcATop,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft, // posisi rata kiri
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HalamanUtama(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF2D90E5),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Title Text
                    const Text(
                      'Pendaftaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Buat akunmu sekarang',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Input Fields
                    _buildTextField(
                      controller: _nameController,
                      icon: Icons.person,
                      hintText: 'Nama',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hintText: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      icon: Icons.lock,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmController,
                      icon: Icons.verified_user,
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 75),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Dengan mendaftar, kamu menyetujui ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'kebijakan privasi.',
                              style: TextStyle(
                                color: Colors.blue[300],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _register(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 120,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          backgroundColor: Color(0xFF2050B4),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'DAFTAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Masuk',
                              style: TextStyle(
                                color: Colors.blue[300],
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HalamanMasuk(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white70),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ),
    );
  }
}
