import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

class AppAuthState {
  const AppAuthState({required this.loggedIn, this.role = 'user'});

  final bool loggedIn;
  final String role;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn.instance;

  String? _verificationId;

  Stream<AppAuthState> get authState => _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return const AppAuthState(loggedIn: false);
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final role = (doc.data()?['role'] ?? 'user') as String;
        return AppAuthState(loggedIn: true, role: role);
      });

  Future<void> sendOtp(String phone) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) => throw Exception(e.message),
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOtp({required String otp, String name = 'Cashy User', String? referralCode}) async {
    if (_verificationId == null) {
      throw Exception('Please request OTP first.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    final result = await _auth.signInWithCredential(credential);
    await _createOrUpdateUser(result.user!, name: name, referralCode: referralCode);
  }

  Future<void> signInWithGoogle({String? referralCode}) async {
    await _google.initialize();
    final user = await _google.authenticate();
    final auth = await user.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    final result = await _auth.signInWithCredential(credential);
    await _createOrUpdateUser(result.user!, name: user.displayName ?? 'Google User', referralCode: referralCode);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }

  Future<void> _createOrUpdateUser(User user, {required String name, String? referralCode}) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final myCode = const Uuid().v4().substring(0, 8).toUpperCase();
      await ref.set({
        'uid': user.uid,
        'name': name,
        'phone': user.phoneNumber ?? '',
        'coins': 0,
        'balance': 0.0,
        'referrals': 0,
        'referralCode': myCode,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSpinDate': '',
        'adViewsToday': 0,
        'adViewsDate': '',
      });
      if (referralCode != null && referralCode.isNotEmpty) {
        final match = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: referralCode)
            .limit(1)
            .get();
        if (match.docs.isNotEmpty) {
          await _firestore.runTransaction((tx) async {
            final owner = match.docs.first.reference;
            tx.update(owner, {'coins': FieldValue.increment(50), 'referrals': FieldValue.increment(1)});
            tx.update(ref, {'coins': FieldValue.increment(50)});
          });
        }
      }
    }
  }
}
