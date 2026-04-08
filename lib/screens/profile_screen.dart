import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Profile')),
      child: StreamBuilder(
        stream: FirestoreService.instance.watchUser(),
        builder: (context, snapshot) {
          final u = snapshot.data?.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: ListTile(title: const Text('Name'), subtitle: Text('${u['name'] ?? ''}'))),
              Card(child: ListTile(title: const Text('Phone'), subtitle: Text('${u['phone'] ?? ''}'))),
              Card(child: ListTile(title: const Text('Referral Code'), subtitle: Text('${u['referralCode'] ?? ''}'))),
              Card(child: ListTile(title: const Text('Referrals'), subtitle: Text('${u['referrals'] ?? 0}'))),
              ElevatedButton(onPressed: AuthService.instance.signOut, child: const Text('Logout')),
            ],
          );
        },
      ),
    );
  }
}
