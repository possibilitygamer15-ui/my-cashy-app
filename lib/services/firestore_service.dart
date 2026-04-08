import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_item.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef => _db.collection('users').doc(_uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser() => _userRef.snapshots();

  Stream<List<TaskItem>> watchTasks() {
    return _db
        .collection('tasks')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((e) => TaskItem.fromMap(e.id, e.data())).toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTransactions() {
    return _db
        .collection('transactions')
        .where('uid', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> convertCoinsToBalance() async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_userRef);
      final coins = (snap.data()?['coins'] ?? 0) as int;
      if (coins < 100) {
        throw Exception('Minimum 100 coins needed');
      }
      final convertCoins = (coins ~/ 100) * 100;
      final amount = (convertCoins / 100) * 10;
      tx.update(_userRef, {
        'coins': FieldValue.increment(-convertCoins),
        'balance': FieldValue.increment(amount),
      });
      tx.set(_db.collection('transactions').doc(), {
        'uid': _uid,
        'type': 'credit',
        'amount': amount,
        'description': 'Coins converted to balance',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> claimReward({required int coins, required String source}) async {
    await _db.runTransaction((tx) async {
      tx.update(_userRef, {'coins': FieldValue.increment(coins)});
      tx.set(_db.collection('transactions').doc(), {
        'uid': _uid,
        'type': 'coin_reward',
        'amount': coins,
        'description': source,
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> completeTask(TaskItem task) async {
    final proofRef = _db.collection('users').doc(_uid).collection('taskProofs').doc(task.id);
    final proofSnap = await proofRef.get();
    if (proofSnap.exists) {
      throw Exception('Task already completed.');
    }

    await _db.runTransaction((tx) async {
      tx.set(proofRef, {
        'taskId': task.id,
        'completedAt': DateTime.now().toIso8601String(),
      });
      tx.update(_userRef, {'coins': FieldValue.increment(task.rewardCoins)});
      tx.set(_db.collection('transactions').doc(), {
        'uid': _uid,
        'type': 'coin_reward',
        'amount': task.rewardCoins,
        'description': 'Task completed: ${task.title}',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<int> spinReward() async {
    final nowDate = DateTime.now().toIso8601String().split('T').first;
    final user = await _userRef.get();
    final last = (user.data()?['lastSpinDate'] ?? '') as String;
    if (last == nowDate) throw Exception('Daily spin already used.');

    final reward = [5, 10, 15, 20, 25, 30, 50][Random().nextInt(7)];
    await _db.runTransaction((tx) async {
      tx.update(_userRef, {'lastSpinDate': nowDate, 'coins': FieldValue.increment(reward)});
      tx.set(_db.collection('transactions').doc(), {
        'uid': _uid,
        'type': 'coin_reward',
        'amount': reward,
        'description': 'Daily spin reward',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    return reward;
  }

  Future<int> scratchReward() async {
    final payout = Random().nextInt(100) < 25;
    final reward = payout ? (5 + Random().nextInt(46)) : 0;
    if (reward > 0) {
      await claimReward(coins: reward, source: 'Scratch card reward');
    }
    return reward;
  }

  Future<void> requestWithdrawal({required double amount, required String upiId}) async {
    if (amount < 50) throw Exception('Minimum ₹50 withdrawal');
    await _db.runTransaction((tx) async {
      final user = await tx.get(_userRef);
      final balance = ((user.data()?['balance'] ?? 0) as num).toDouble();
      if (balance < amount) throw Exception('Insufficient balance.');
      tx.update(_userRef, {'balance': FieldValue.increment(-amount)});
      tx.set(_db.collection('withdrawals').doc(), {
        'uid': _uid,
        'amount': amount,
        'upiId': upiId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
      tx.set(_db.collection('transactions').doc(), {
        'uid': _uid,
        'type': 'debit',
        'amount': amount,
        'description': 'Withdrawal request',
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }
}
