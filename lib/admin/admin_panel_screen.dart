import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();

  final _db = FirebaseFirestore.instance;

  Future<void> _addTask() async {
    await _db.collection('tasks').add({
      'title': _titleCtrl.text.trim(),
      'link': _linkCtrl.text.trim(),
      'rewardCoins': int.parse(_rewardCtrl.text.trim()),
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _titleCtrl.clear();
    _linkCtrl.clear();
    _rewardCtrl.clear();
  }

  Future<void> _updateWithdrawal(String id, String status) async {
    await _db.collection('withdrawals').doc(id).update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add task', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: 'Link')),
          TextField(controller: _rewardCtrl, decoration: const InputDecoration(labelText: 'Reward coins')),
          ElevatedButton(onPressed: _addTask, child: const Text('Add Task')),
          const SizedBox(height: 16),
          const Text('Pending withdrawals', style: TextStyle(fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('withdrawals').where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return Column(
                children: docs
                    .map((d) => Card(
                          child: ListTile(
                            title: Text('₹${d['amount']} - ${d['upiId']}'),
                            subtitle: Text('UID: ${d['uid']}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                TextButton(onPressed: () => _updateWithdrawal(d.id, 'approved'), child: const Text('Approve')),
                                TextButton(onPressed: () => _updateWithdrawal(d.id, 'rejected'), child: const Text('Reject')),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
