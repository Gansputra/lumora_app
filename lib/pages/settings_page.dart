import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumora_app/pages/halaman_utama.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void showPopup(String title, String message, {bool success = false}) {
    final ctx = context;
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: "Popup",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: success
                      ? [Color(0xFF43CEA2), Color(0xFF185A9D)]
                      : [Color(0xFFFF512F), Color(0xFFDD2476)],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  // Fungsi untuk memilih file gambar (pakai image_picker)
  Future<String?> _pickAndUploadAvatar(String userId) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return null;
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileExt = image.name.split('.').last;
      final fileName = 'avatars/$userId.$fileExt';
      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );
      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      print('Upload error: $e');
      showPopup('Error', 'Gagal upload foto: $e');
      return null;
    }
  }

  // Fungsi untuk hapus avatar dari storage dan DB
  Future<void> _deleteAvatar(String? avatarUrl, String userId) async {
    try {
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        final storage = Supabase.instance.client.storage.from('avatars');
        final fileName = avatarUrl.split('/').last;
        await storage.remove([fileName]);
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);
      setState(() {
        photoUrl = null;
      });
      showPopup('Berhasil', 'Foto profil berhasil dihapus', success: true);
    } catch (e) {
      showPopup('Error', 'Gagal menghapus foto: $e');
    }
  }

  void _showAvatarDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ganti Foto Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final url = await _pickAndUploadAvatar(user.id);
                      if (url != null) {
                        await Supabase.instance.client
                            .from('profiles')
                            .update({'avatar_url': url})
                            .eq('id', user.id);
                        await fetchUserData();
                        showPopup(
                          'Berhasil',
                          'Foto profil berhasil diganti',
                          success: true,
                        );
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Ganti'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (photoUrl == null || photoUrl!.isEmpty)
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            await _deleteAvatar(photoUrl, user.id);
                            await fetchUserData();
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HalamanUtama()),
        (route) => false,
      );
    }
  }

  String? username;
  String? email;
  String? photoUrl;
  String? userId;
  DateTime? joinedAt;
  bool isLoading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordOldController = TextEditingController();
  final TextEditingController _passwordNewController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('username, created_at, userId, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    setState(() {
      username = profile != null ? profile['username'] as String? : null;
      email = user.email;
      joinedAt = (profile != null && profile['created_at'] != null)
          ? DateTime.parse(profile['created_at'])
          : null;
      _usernameController.text = username ?? '';
      userId = profile != null ? profile['userId']?.toString() : null;
      photoUrl = profile != null ? profile['avatar_url'] as String? : null;
      isLoading = false;
    });
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Profil Tidak Ditemukan',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text('Data profil tidak ditemukan di database.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> updateUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    // Cek apakah username sudah ada di Supabase
    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('username', newUsername)
        .neq('id', user.id) // pastikan bukan user sendiri
        .maybeSingle();

    if (existing != null) {
      showPopup('Username Sudah Diambil', 'Silakan pilih username lain');
      return;
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'username': newUsername})
          .eq('id', user.id);
      setState(() {
        username = newUsername;
      });
      Navigator.of(context).pop();
      showPopup('Berhasil', 'Username berhasil diubah', success: true);
    } catch (e) {
      if (e.toString().contains('duplicate key value') ||
          e.toString().contains('23505')) {
        showPopup('Username Sudah Diambil', 'Silakan pilih username lain');
      } else {
        showPopup('Error', 'Gagal mengubah username: $e');
      }
    }
  }

  Future<void> updatePassword() async {
    final oldPassword = _passwordOldController.text.trim();
    final newPassword = _passwordNewController.text.trim();
    final confirmPassword = _passwordConfirmController.text.trim();
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
      return;
    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal', style: TextStyle(color: Colors.red)),
          content: const Text('Password baru dan konfirmasi tidak sama'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      // Cek password lama dengan login ulang
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final email = user.email;
      await Supabase.instance.client.auth.signInWithPassword(
        email: email!,
        password: oldPassword,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil', style: TextStyle(color: Colors.green)),
          content: const Text('Password berhasil diubah'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _passwordOldController.clear();
      _passwordNewController.clear();
      _passwordConfirmController.clear();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal', style: TextStyle(color: Colors.red)),
          content: Text('Gagal mengubah password: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola informasi akun dan status kamu di sini',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // ===== CARD PROFILE =====
                  _card(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarDialog,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFF5B8DEF),
                            backgroundImage:
                                (photoUrl != null && photoUrl!.isNotEmpty)
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: (photoUrl == null || photoUrl!.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username ?? '-',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(email ?? '-'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _badge('Aktif', Colors.green),
                                  const SizedBox(width: 8),
                                  _badge(
                                    'ID: ${userId ?? '-'}',
                                    Colors.grey.shade300,
                                    textColor: Colors.black,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                joinedAt != null
                                    ? 'Bergabung sejak ' +
                                          DateFormat(
                                            'dd MMMM yyyy',
                                            'id_ID',
                                          ).format(joinedAt!)
                                    : '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== INFORMASI AKUN =====
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Username', username ?? '-'),
                        _infoRow('Email', email ?? '-'),
                        _infoRow('Status', 'Aktif', valueColor: Colors.green),
                        _infoRow('User ID', userId ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== AKSI =====
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Ganti Username'),
                                    content: TextField(
                                      controller: _usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username Baru',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: updateUsername,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text('Simpan'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Ganti Password'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _passwordOldController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Password Lama',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _passwordNewController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Password Baru',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller:
                                              _passwordConfirmController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Konfirmasi Password Baru',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: updatePassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[700],
                                        ),
                                        child: const Text('Simpan'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.lock),
                              label: const Text('Ganti Password'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  // ===== WIDGET HELPER =====

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  static Widget _badge(
    String text,
    Color bgColor, {
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }

  static Widget _infoRow(
    String label,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

/// Helper function to navigate to SettingsPage with slide transition
void navigateToSettingsPage(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SettingsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profil',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola informasi akun dan status kamu di sini',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // ===== CARD PROFILE =====
            _card(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFF5B8DEF),
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sahroni',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('sahroni2@gmail.com'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _badge('Aktif', Colors.green),
                            const SizedBox(width: 8),
                            _badge(
                              'ID: 1',
                              Colors.grey.shade300,
                              textColor: Colors.black,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bergabung sejak 07 January 2026',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== INFORMASI AKUN =====
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Username', 'Sahroni'),
                  _infoRow('Email', 'sahroni2@gmail.com'),
                  _infoRow('Status', 'Aktif', valueColor: Colors.green),
                  _infoRow('User ID', '1'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== AKSI =====
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.lock),
                        label: const Text('Ganti Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  static Widget _badge(
    String text,
    Color bgColor, {
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }

  static Widget _infoRow(
    String label,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
