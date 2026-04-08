import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController(text: '+91');
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendOtp(_phoneCtrl.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.verifyOtp(
        otp: _otpCtrl.text.trim(),
        name: _nameCtrl.text.trim().isEmpty ? 'Cashy User' : _nameCtrl.text.trim(),
        referralCode: _refCtrl.text.trim(),
      );
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle(referralCode: _refCtrl.text.trim());
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CashyPro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Referral Code (optional)')),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (+countrycode)')),
            if (_otpSent) TextField(controller: _otpCtrl, decoration: const InputDecoration(labelText: 'OTP')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
              child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
            ),
            TextButton.icon(
              onPressed: _loading ? null : _googleLogin,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
