import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/support_chat_message.dart';

class SupportChatService {
  SupportChatService._();

  static final SupportChatService instance = SupportChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _messageRef => _db
      .collection('users')
      .doc(_uid)
      .collection('supportChats')
      .doc('primary')
      .collection('messages');

  Stream<List<SupportChatMessage>> watchMessages() {
    return _messageRef.orderBy('createdAt', descending: false).snapshots().map(
          (snap) => snap.docs.map((doc) => SupportChatMessage.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<void> sendUserMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty) return;

    await _messageRef.add({
      'role': 'user',
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final reply = await _buildReply(message);
    await _messageRef.add({
      'role': 'assistant',
      'text': reply,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _buildReply(String userMessage) async {
    if (_geminiApiKey.isEmpty) {
      return _localFallbackReply(userMessage);
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {
                'text': 'You are CashyPro support. Be concise, safe, and practical. '
                    'Only help with app account, earning, wallet, withdrawal, and referral issues.'
              }
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': userMessage}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 220,
          }
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = (decoded['candidates'] as List<dynamic>? ?? []);
        if (candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = (content?['parts'] as List<dynamic>? ?? []);
          if (parts.isNotEmpty) {
            final text = (parts.first['text'] ?? '').toString().trim();
            if (text.isNotEmpty) return text;
          }
        }
      }
    } catch (_) {
      // Fall back to local support response.
    }

    return _localFallbackReply(userMessage);
  }

  String _localFallbackReply(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('withdraw') || lower.contains('payout') || lower.contains('upi')) {
      return 'Withdrawal checklist:\n'
          '1) Minimum ₹50 balance is required.\n'
          '2) Verify your UPI ID format.\n'
          '3) Requests are created as pending and need admin approval.\n'
          'If money is deducted but not received, share the amount and request time.';
    }

    if (lower.contains('spin') || lower.contains('daily')) {
      return 'Spin support: one spin is allowed per day and costs 10 coins. '
          'If you were charged without reward, refresh after 1 minute and check transaction history.';
    }

    if (lower.contains('task') || lower.contains('coin') || lower.contains('reward')) {
      return 'Task rewards are granted once per task. Keep the task screen open for the full validation period before returning.';
    }

    if (lower.contains('login') || lower.contains('otp') || lower.contains('phone')) {
      return 'OTP login tips: confirm country code, retry after 30 seconds, and ensure Play Services are updated on Android for auto verification.';
    }

    return 'I can help with OTP/login, rewards, tasks, spin, wallet conversion, and withdrawals. '
        'Please share your issue in one sentence with any error text shown in the app.';
  }
}
