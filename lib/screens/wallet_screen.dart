import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _upiCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _convert() async {
    try {
      await FirestoreService.instance.convertCoinsToBalance();
      _show('Converted successfully');
    } catch (e) {
      _show(e.toString());
    }
  }

  Future<void> _withdraw() async {
    try {
      await FirestoreService.instance.requestWithdrawal(
        amount: double.parse(_amountCtrl.text.trim()),
        upiId: _upiCtrl.text.trim(),
      );
      _show('Withdrawal requested');
    } catch (e) {
      _show(e.toString());
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
            child: Row(
              children: [
                Expanded(child: TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: '₹ Amount'))),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: _convert, child: const Text('Convert 100 coins = ₹10')),
              ElevatedButton(onPressed: _withdraw, child: const Text('Request Withdrawal (₹50 min)')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.watchTransactions(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return Card(
                      child: ListTile(
                        title: Text('${data['description']}'),
                        subtitle: Text('Status: ${data['status']}'),
                        trailing: Text('₹/C ${data['amount']}'),
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
