import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/lulu_coin_badge.dart';
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
          final name = data['name'] ?? 'Cashy User';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LuluCoinBadge(),
                        const SizedBox(width: 10),
                        Text('Lulu Coin',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Welcome back, $name',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 6),
                    const Text(
                      'Track your earnings, complete offers, and manage payouts in one place.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              StatCard(title: 'Lulu Coins', value: '${data['coins'] ?? 0}', icon: Icons.monetization_on),
              StatCard(title: 'Balance', value: '₹${data['balance'] ?? 0}', icon: Icons.currency_rupee),
              StatCard(title: 'Referrals', value: '${data['referrals'] ?? 0}', icon: Icons.group),
            ],
          );
        },
      ),
    );
  }
}
