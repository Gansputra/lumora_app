import 'dart:ui';

import 'package:lumora_app/pages/halaman_utama.dart';
import 'package:lumora_app/pages/halaman_daftar.dart';
import 'package:flutter/material.dart';
import 'package:lumora_app/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({Key? key}) : super(key: key);

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final input = _emailController.text.trim();
    final password = _passwordController.text;

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

    if (input.isEmpty || password.isEmpty) {
      showPopup('Error', 'Email/username dan password harus diisi');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? email;
      String? userName;
      // Jika input mengandung '@', anggap sebagai email
      if (input.contains('@')) {
        email = input;
      } else {
        // Cari email berdasarkan username di tabel profiles
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('id, username, email')
            .eq('username', input)
            .limit(1)
            .maybeSingle();
        if (profileRes == null) {
          showPopup('Salah', 'Username tidak ditemukan');
          return;
        }
        email = profileRes['email'] as String?;
        userName = profileRes['username'] as String?;
        if (email == null) {
          showPopup('Salah', 'Email tidak ditemukan untuk username ini');
          return;
        }
      }

      // Login ke Supabase Auth
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authRes.user == null) {
        showPopup('Salah', 'Email/username atau password salah');
        return;
      }

      // Cek verifikasi email
      final user = authRes.user;
      if (user != null && user.emailConfirmedAt == null) {
        showPopup(
          'Verifikasi Diperlukan',
          'Harap verifikasi email anda terlebih dahulu',
        );
        return;
      }

      // Ambil username jika login pakai email
      if (userName == null) {
        // Cari username di profiles
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', authRes.user!.id)
            .maybeSingle();
        userName = profileRes != null
            ? profileRes['username'] as String?
            : null;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil', style: TextStyle(color: Colors.green)),
          content: const Text('Login berhasil'),
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
        MaterialPageRoute(
          builder: (context) => HomePage(userName: userName ?? email!),
        ),
      );
    } on AuthException catch (e) {
      if (e.message != null &&
          (e.message!.contains('email not confirmed') ||
              e.message!.contains('Email not confirmed') ||
              e.message!.contains('email_not_confirmed'))) {
        showPopup(
          'Verifikasi Diperlukan',
          'Harap verifikasi email anda terlebih dahulu',
        );
      } else {
        showPopup('Error', 'Terjadi error: ${e.message}');
      }
    } catch (e) {
      showPopup('Error', 'Terjadi error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Stack(
            children: [
              // HEADER IMAGE
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Image.asset(
                    'assets/images/daun.png',
                    fit: BoxFit.cover,
                    color: Colors.blue.shade700.withOpacity(0.6),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 90,
                ),
                child: Column(
                  children: [
                    // BACK BUTTON
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF2D90E5),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Masuk ke akun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Selamat datang kembali!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 120),

                    // ===== MODERN INPUT =====
                    _modernTextField(
                      controller: _emailController,
                      hint: 'E-mail atau Username',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 18),

                    _modernTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
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

                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanDaftar(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // BUTTON
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2050B4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 120,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  Widget _modernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
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
              suffixIcon: suffixIcon,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
