import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_item.dart';
import '../services/ad_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  bool scratchUnlocked = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.init();
  }

  Future<void> _watchAd() async {
    await AdService.instance.watchRewardedAd(
      onError: _show,
      onReward: () {
        setState(() => scratchUnlocked = true);
        _show('Ad reward credited + scratch unlocked');
      },
    );
  }

  Future<void> _spin() async {
    try {
      final reward = await FirestoreService.instance.spinReward();
      _show('You won $reward coins (10 coin spin fee applied)');
    } catch (e) {
      _show(e.toString());
    }
  }

  Future<void> _scratch() async {
    if (!scratchUnlocked) {
      _show('Unlock scratch by completing ad/task first');
      return;
    }
    final reward = await FirestoreService.instance.scratchReward();
    setState(() => scratchUnlocked = false);
    _show(reward > 0 ? 'Scratch reward: $reward coins' : 'Better luck next time');
  }

  Future<void> _startTask(TaskItem task) async {
    final uri = Uri.parse(task.link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _show('Unable to open link');
      return;
    }
    _show('Stay on task for 8 seconds...');
    await Future<void>.delayed(const Duration(seconds: 8));
    try {
      await FirestoreService.instance.completeTask(task);
      setState(() => scratchUnlocked = true);
      _show('Task completed. ${task.rewardCoins} coins added');
    } catch (e) {
      _show(e.toString());
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Earn Coins')),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Rewarded Ad (+20 coins)'),
              subtitle: const Text('Maximum 10 ads/day'),
              trailing: ElevatedButton(onPressed: _watchAd, child: const Text('Watch')),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Daily Spin Wheel'),
              subtitle: const Text('One spin daily (cost 10 coins), win 5-50 coins'),
              trailing: ElevatedButton(onPressed: _spin, child: const Text('Spin')),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Scratch Card'),
              subtitle: const Text('25% payout chance'),
              trailing: ElevatedButton(onPressed: _scratch, child: const Text('Scratch')),
            ),
          ),
          const SizedBox(height: 8),
          Text('Tasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          StreamBuilder<List<TaskItem>>(
            stream: FirestoreService.instance.watchTasks(),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No tasks available')));
              }
              return Column(
                children: tasks
                    .map((task) => Card(
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Text('Reward: ${task.rewardCoins} coins | 8 sec validation'),
                            trailing: ElevatedButton(
                              onPressed: () => unawaited(_startTask(task)),
                              child: const Text('Start'),
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
