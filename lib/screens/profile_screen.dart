import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/pro_action_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _adminPasswordCtrl = TextEditingController();
  final TextEditingController _adminBirthdayCtrl = TextEditingController();
  bool _unlocking = false;

  @override
  void dispose() {
    _adminPasswordCtrl.dispose();
    _adminBirthdayCtrl.dispose();
    super.dispose();
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _unlockAdmin() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      await AuthService.instance.unlockAdmin(
        password: _adminPasswordCtrl.text,
        birthday: _adminBirthdayCtrl.text,
      );
      _show('Admin unlocked. Please reopen app screen if needed.');
      _adminPasswordCtrl.clear();
      _adminBirthdayCtrl.clear();
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Profile')),
      child: StreamBuilder(
        stream: FirestoreService.instance.watchUser(),
        builder: (context, snapshot) {
          final u = snapshot.data?.data() ?? {};
          final role = '${u['role'] ?? 'user'}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: ListTile(title: const Text('Name'), subtitle: Text('${u['name'] ?? ''}'))),
              const SizedBox(height: 8),
              Card(child: ListTile(title: const Text('Phone'), subtitle: Text('${u['phone'] ?? ''}'))),
              const SizedBox(height: 8),
              Card(child: ListTile(title: const Text('Referral Code'), subtitle: Text('${u['referralCode'] ?? ''}'))),
              const SizedBox(height: 8),
              Card(child: ListTile(title: const Text('Referrals'), subtitle: Text('${u['referrals'] ?? 0}'))),
              const SizedBox(height: 8),
              Card(child: ListTile(title: const Text('Role'), subtitle: Text(role.toUpperCase()))),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Admin Unlock', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _adminPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Enter admin password'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _adminBirthdayCtrl,
                        decoration: const InputDecoration(labelText: 'Security answer (birthday: 8/2/2008)'),
                      ),
                      const SizedBox(height: 10),
                      ProActionButton(
                        label: 'Unlock Admin',
                        icon: Icons.admin_panel_settings,
                        onPressed: _unlockAdmin,
                        loading: _unlocking,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ProActionButton(
                label: 'Logout',
                icon: Icons.logout,
                onPressed: AuthService.instance.signOut,
                expand: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
