import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? username;
  String? email;
  String? photoUrl;
  DateTime? joinedAt;
  bool isLoading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordOldController = TextEditingController();
  final TextEditingController _passwordNewController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

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
        .select('username, created_at')
        .eq('id', user.id)
        .maybeSingle();
    setState(() {
      username = profile != null ? profile['username'] as String? : null;
      email = user.email;
      joinedAt = (profile != null && profile['created_at'] != null)
          ? DateTime.parse(profile['created_at'])
          : null;
      _usernameController.text = username ?? '';
      isLoading = false;
    });
  }

  Future<void> updateUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'username': newUsername})
        .eq('id', user.id);
    setState(() {
      username = newUsername;
    });
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil', style: TextStyle(color: Colors.green)),
        content: const Text('Username berhasil diubah'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> updatePassword() async {
    final oldPassword = _passwordOldController.text.trim();
    final newPassword = _passwordNewController.text.trim();
    final confirmPassword = _passwordConfirmController.text.trim();
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) return;
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
      await Supabase.instance.client.auth.signInWithPassword(email: email!, password: oldPassword);
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));
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
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF2050B4),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: const AssetImage('assets/images/default_profile.png'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            username ?? '-',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email ?? '-',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            joinedAt != null ? 'Bergabung: ' + DateFormat('d MMMM yyyy', 'id_ID').format(joinedAt!) : '-',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Ganti Username'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2050B4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
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
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: updateUsername,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2050B4),
                                          ),
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.lock),
                                label: const Text('Ganti Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
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
                                            controller: _passwordConfirmController,
                                            obscureText: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Konfirmasi Password Baru',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
