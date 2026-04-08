import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/pro_action_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _upiCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _busyConvert = false;
  bool _busyWithdraw = false;

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _convert() async {
    if (_busyConvert) return;
    setState(() => _busyConvert = true);
    try {
      await FirestoreService.instance.convertCoinsToBalance();
      _show('Converted successfully');
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busyConvert = false);
    }
  }

  Future<void> _withdraw() async {
    if (_busyWithdraw) return;
    setState(() => _busyWithdraw = true);
    try {
      await FirestoreService.instance.requestWithdrawal(
        amount: double.parse(_amountCtrl.text.trim()),
        upiId: _upiCtrl.text.trim(),
      );
      _show('Withdrawal requested');
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busyWithdraw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Wallet')),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Quick Withdraw', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID')),
                    const SizedBox(height: 8),
                    TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: '₹ Amount')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ProActionButton(
                            label: 'Convert Coins',
                            icon: Icons.currency_exchange,
                            onPressed: _convert,
                            loading: _busyConvert,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ProActionButton(
                            label: 'Withdraw',
                            icon: Icons.account_balance_wallet,
                            onPressed: _withdraw,
                            loading: _busyWithdraw,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('100 coins = ₹10 • minimum withdrawal ₹50'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.watchTransactions(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return Card(
                      child: ListTile(
                        title: Text('${data['description']}'),
                        subtitle: Text('Status: ${data['status']}'),
                        trailing: Text('₹/C ${data['amount']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
