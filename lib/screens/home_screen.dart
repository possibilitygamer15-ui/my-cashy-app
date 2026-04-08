import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('CashyPro Home')),
      child: StreamBuilder(
        stream: FirestoreService.instance.watchUser(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatCard(title: 'Coins', value: '${data['coins'] ?? 0}', icon: Icons.monetization_on),
              StatCard(title: 'Balance', value: '₹${data['balance'] ?? 0}', icon: Icons.currency_rupee),
              StatCard(title: 'Referrals', value: '${data['referrals'] ?? 0}', icon: Icons.group),
            ],
          );
        },
      ),
    );
  }
}
