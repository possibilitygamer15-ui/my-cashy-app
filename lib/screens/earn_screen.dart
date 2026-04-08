import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/refer_app_item.dart';
import '../models/task_item.dart';
import '../services/ad_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/pro_action_button.dart';

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
        _show('Lulu reward credited + scratch unlocked');
      },
    );
  }

  Future<void> _spin() async {
    try {
      final reward = await FirestoreService.instance.spinReward();
      _show('You won $reward Lulu coins (10 coin spin fee applied)');
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
    _show(reward > 0 ? 'Scratch reward: $reward Lulu coins' : 'Better luck next time');
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
      _show('Task completed. ${task.rewardCoins} Lulu coins added');
    } catch (e) {
      _show(e.toString());
    }
  }

  Future<void> _startReferApp(ReferAppItem app) async {
    final uri = Uri.parse(app.link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _show('Unable to open app link');
      return;
    }

    _show('Install and keep app open for 8 seconds to claim commission...');
    await Future<void>.delayed(const Duration(seconds: 8));
    try {
      await FirestoreService.instance.claimReferAppInstall(app);
      _show('Refer commission credited: ${app.commissionCoins} Lulu coins');
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
      appBar: AppBar(title: const Text('Earn Lulu Coins')),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Complete quick actions to earn Lulu coins faster. Rewards are credited instantly after verification.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Rewarded Ad (+20 Lulu)'),
              subtitle: const Text('Maximum 10 ads/day'),
              trailing: ProActionButton(label: 'Watch', icon: Icons.ondemand_video, onPressed: _watchAd),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Daily Spin Wheel'),
              subtitle: const Text('One spin daily (cost 10 Lulu), win 5-50 Lulu'),
              trailing: ProActionButton(label: 'Spin', icon: Icons.casino, onPressed: _spin),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Scratch Card'),
              subtitle: const Text('25% payout chance'),
              trailing: ProActionButton(label: 'Scratch', icon: Icons.style, onPressed: _scratch),
            ),
          ),
          const SizedBox(height: 12),
          Text('Refer Apps', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StreamBuilder<List<ReferAppItem>>(
            stream: FirestoreService.instance.watchReferApps(),
            builder: (context, snapshot) {
              final apps = snapshot.data ?? [];
              if (apps.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No refer apps available now'),
                  ),
                );
              }

              return Column(
                children: apps
                    .map((app) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(app.name),
                              subtitle: Text('Install via link and earn ${app.commissionCoins} Lulu commission'),
                              trailing: ProActionButton(
                                label: 'Install',
                                icon: Icons.download,
                                onPressed: () => unawaited(_startReferApp(app)),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Tasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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
                    .map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(task.title),
                              subtitle: Text('Reward: ${task.rewardCoins} Lulu | 8 sec validation'),
                              trailing: ProActionButton(
                                label: 'Start',
                                icon: Icons.play_arrow,
                                onPressed: () => unawaited(_startTask(task)),
                              ),
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
