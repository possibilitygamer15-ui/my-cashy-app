class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.coins,
    required this.balance,
    required this.referrals,
    required this.referralCode,
    required this.role,
  });

  final String uid;
  final String name;
  final String phone;
  final int coins;
  final double balance;
  final int referrals;
  final String referralCode;
  final String role;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'coins': coins,
      'balance': balance,
      'referrals': referrals,
      'referralCode': referralCode,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      coins: (map['coins'] ?? 0) as int,
      balance: ((map['balance'] ?? 0) as num).toDouble(),
      referrals: (map['referrals'] ?? 0) as int,
      referralCode: (map['referralCode'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
    );
  }
}
